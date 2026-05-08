// Registro do que o app precisa: nuvem, banco no aparelho, repositórios e trabalho em segundo plano.
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/connectivity_service.dart';
import 'core/services/database_helper.dart';
import 'core/services/dio_client.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_config.dart';
import 'core/services/theme_controller.dart';
import 'modules/auth/repositories/auth_repository.dart';
import 'modules/client/repositories/cliente_repository.dart';
import 'modules/notifications/repositories/notificacao_repository.dart';
import 'modules/service_order/repositories/ordem_servico_repository.dart';

/// Prepara tudo antes de mostrar a primeira tela (chamado no início do app).
Future<void> setupApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );

  // Cria o cliente HTTP cedo para a primeira chamada ao servidor não atrasar.
  // ignore: unused_local_variable
  final dio = DioClient.instance;

  await DatabaseHelper.instance.database;

  final connectivity = ConnectivityService.instance;
  await connectivity.init();

  // Um único objeto de cada tipo, compartilhado por todo o app.
  final getIt = GetIt.instance;
  getIt.registerSingleton<ConnectivityService>(connectivity);
  getIt.registerSingleton<AuthRepository>(AuthRepository());
  getIt.registerSingleton<ClienteRepository>(ClienteRepository());
  getIt.registerSingleton<OrdemServicoRepository>(OrdemServicoRepository());
  getIt.registerSingleton<NotificacaoRepository>(NotificacaoRepository());
  getIt.registerSingleton<StorageService>(StorageService.instance);
  final themeController = ThemeController();
  getIt.registerSingleton<ThemeController>(themeController);
  await themeController.load();

  final sync = OfflineSyncService(
    authRepo: getIt<AuthRepository>(),
    clienteRepo: getIt<ClienteRepository>(),
    osRepo: getIt<OrdemServicoRepository>(),
    notifRepo: getIt<NotificacaoRepository>(),
    connectivity: connectivity,
  );
  getIt.registerSingleton<OfflineSyncService>(sync);
  sync.start();
}
