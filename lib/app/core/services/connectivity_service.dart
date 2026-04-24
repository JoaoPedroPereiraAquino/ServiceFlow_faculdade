import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Wrapper sobre `connectivity_plus` que expõe um `ValueNotifier<bool>`
/// indicando se há conexão online no momento.
///
/// É observado pelo `OfflineSyncService` para disparar a sincronização.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    isOnline.value = _hasNetwork(results);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = _hasNetwork(results);
    });
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _sub?.cancel();
    isOnline.dispose();
  }
}
