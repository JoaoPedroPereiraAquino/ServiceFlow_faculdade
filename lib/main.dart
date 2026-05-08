// ServiceFlow — app de ordens de serviço.
// Configura tema, barra do sistema e tela inicial conforme a sessão na nuvem.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_setup.dart';
import 'app/core/services/theme_controller.dart';
import 'app/core/theme/app_colors.dart';
import 'app/core/theme/app_theme.dart';
import 'app/modules/auth/views/login_view.dart';
import 'app/modules/dashboard/views/main_shell.dart';

/// Tema escolhido pelo usuário vira claro/escuro concreto para o sistema.
Brightness _brightnessForThemeMode(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
}

Future<void> main() async {
  await setupApp();

  runApp(const ServiceFlowApp());
}

class ServiceFlowApp extends StatelessWidget {
  const ServiceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = GetIt.I<ThemeController>();
    return ListenableBuilder(
      listenable: tc,
      builder: (_, __) {
        // Ajusta as cores do app e da barra de status ao tema (claro ou escuro).
        final b = _brightnessForThemeMode(tc.mode);
        final dark = b == Brightness.dark;
        AppColors.sync(b);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          title: 'ServiceFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: tc.mode,
          builder: (_, child) => child ?? const SizedBox.shrink(),
          home: const _AuthGate(),
        );
      },
    );
  }
}

/// Abre o login ou o app principal conforme há sessão ativa na nuvem.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Stream<AuthState> _stream =
      Supabase.instance.client.auth.onAuthStateChange;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _stream,
      builder: (_, __) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MainShell();
        }
        return const LoginView();
      },
    );
  }
}

/// Tela de espera simples, caso queira mostrar algo ao abrir o app.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
