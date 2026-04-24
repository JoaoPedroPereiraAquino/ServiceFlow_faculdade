import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/client/repositories/cliente_repository.dart';
import '../../modules/notifications/repositories/notificacao_repository.dart';
import '../../modules/service_order/repositories/ordem_servico_repository.dart';
import 'connectivity_service.dart';

/// Serviço central de sincronização offline-first.
///
/// - Observa `ConnectivityService.isOnline`.
/// - Quando volta a ficar online, dispara um sync em background:
///   1) clientes pendentes -> Supabase
///   2) ordens de serviço pendentes -> Supabase
///   3) pull (clientes / OS / notificações) do servidor para o local
class OfflineSyncService {
  OfflineSyncService({
    required this.authRepo,
    required this.clienteRepo,
    required this.osRepo,
    required this.notifRepo,
    required this.connectivity,
  });

  final AuthRepository authRepo;
  final ClienteRepository clienteRepo;
  final OrdemServicoRepository osRepo;
  final NotificacaoRepository notifRepo;
  final ConnectivityService connectivity;

  /// `true` enquanto um sync está em andamento.
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  /// Última mensagem amigável de status (UI pode opcionalmente exibir).
  final ValueNotifier<String?> lastStatus = ValueNotifier<String?>(null);

  bool _initialized = false;

  void start() {
    if (_initialized) return;
    _initialized = true;

    connectivity.isOnline.addListener(() {
      if (connectivity.isOnline.value) {
        unawaited(syncAll());
      }
    });
  }

  Future<void> syncAll() async {
    if (syncing.value) return;
    if (!connectivity.isOnline.value) return;
    if (Supabase.instance.client.auth.currentUser == null) return;

    syncing.value = true;
    try {
      await authRepo.sincronizarPerfilPendente();

      // 1) Push CLIENTES primeiro — assim, qualquer OS pendente que tenha
      //    sido criada offline com o cliente também pendente conseguirá
      //    resolver o cliente_remote_id antes de subir.
      final pushedC = await clienteRepo.syncPendentes();

      // 2) Push ORDENS DE SERVIÇO (incluindo upload das fotos no Storage).
      final pushedOs = await osRepo.syncPendentes();

      // 3) Pull do servidor para refletir alterações feitas em outros devices.
      await clienteRepo.pullDoServidor();
      await osRepo.pullDoServidor();
      await notifRepo.pullDoServidor();

      if (pushedC + pushedOs > 0) {
        lastStatus.value =
            'Sincronizado: $pushedC cliente(s), $pushedOs OS enviadas.';
      } else {
        lastStatus.value = 'Tudo em dia.';
      }
    } catch (_) {
      lastStatus.value = 'Falha de sincronização — tentaremos novamente.';
    } finally {
      syncing.value = false;
    }
  }
}
