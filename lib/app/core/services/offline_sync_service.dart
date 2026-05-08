// Quando a internet volta, envia o que ficou pendente e busca novidades do servidor.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/client/repositories/cliente_repository.dart';
import '../../modules/notifications/repositories/notificacao_repository.dart';
import '../../modules/service_order/repositories/ordem_servico_repository.dart';
import 'connectivity_service.dart';

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

  /// Indica se uma rodada de envio/busca está em andamento.
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  /// Última mensagem de status (a tela pode mostrar se quiser).
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

      // 1) Envia clientes primeiro: ordens salvas sem internet ligam ao cliente certo depois.
      final pushedC = await clienteRepo.syncPendentes();

      // 2) Envia ordens de serviço e sobe as fotos para o armazenamento na nuvem.
      final pushedOs = await osRepo.syncPendentes();

      // 3) Baixa do servidor o que mudou em outros aparelhos.
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
