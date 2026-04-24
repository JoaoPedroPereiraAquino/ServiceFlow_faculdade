import 'package:flutter/foundation.dart';

/// Logger central do ServiceFlow.
///
/// Em **debug**: imprime via `debugPrint` (cortado em chunks pelo Flutter).
/// Em **release**: vira no-op para não vazar nada via `adb logcat` no device
/// do usuário, e o ProGuard ainda assim remove qualquer chamada residual.
///
/// IMPORTANTE: NUNCA passe dados sensíveis (token, senha, base64 da
/// assinatura, conteúdo completo de fotos). Use `tag` para localizar.
class AppLogger {
  AppLogger._();

  static void d(String tag, Object? message) {
    if (!kDebugMode) return;
    debugPrint('🟢 [$tag] $message');
  }

  static void w(String tag, Object? message) {
    if (!kDebugMode) return;
    debugPrint('🟡 [$tag] $message');
  }

  /// Use para erros recuperáveis. Em produção este método deve ser
  /// substituído por uma chamada ao Sentry/Crashlytics (TODO).
  static void e(String tag, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('🔴 [$tag] $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
