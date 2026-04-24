import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/error_model.dart';
import 'supabase_config.dart';

/// DioClient — singleton com `Interceptors` para injeção automática
/// de Token JWT (do Supabase Auth) e mapeamento de erros padrão.
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${SupabaseConfig.url}/rest/v1/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'apikey': SupabaseConfig.publishableKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _addInterceptors();
  }

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  static DioClient get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          } else {
            options.headers['Authorization'] =
                'Bearer ${SupabaseConfig.publishableKey}';
          }
          options.headers['Prefer'] ??= 'return=representation';
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: ErrorModel.unauthorized,
                type: e.type,
              ),
            );
          }
          handler.next(e);
        },
        onResponse: (response, handler) => handler.next(response),
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        request: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ));
    }
  }
}
