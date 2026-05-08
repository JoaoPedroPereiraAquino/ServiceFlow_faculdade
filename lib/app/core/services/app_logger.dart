// Registra mensagens só em modo de desenvolvimento; em uso real fica silencioso.
// Não coloque senhas, chaves ou dados completos de pessoas nas mensagens.
import 'package:flutter/foundation.dart';

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

  /// Erros que o app pode seguir após registrar. Depois pode ligar a um serviço de relatório de falhas.
  static void e(String tag, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('🔴 [$tag] $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
