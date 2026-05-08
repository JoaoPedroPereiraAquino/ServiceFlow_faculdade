// Perfil: resumo de OS, conta, tema e alertas.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/usuario.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/views/login_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../service_order/models/ordem_servico.dart';
import '../../service_order/repositories/ordem_servico_repository.dart';
import 'profile_edit_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with UiFeedbackMixin {
  Usuario? _usuario;
  OsSummary _summary = const OsSummary();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Usuario? u;
    try {
      u = await GetIt.I<AuthRepository>().currentUser();
      final list = await GetIt.I<OrdemServicoRepository>().listarTodas();
      if (!mounted) return;
      setState(() {
        _usuario = u;
        _summary = OsSummary.fromList(list);
      });
    } catch (_) {
      if (!mounted) return;
      if (u != null) {
        setState(() {
          _usuario = u;
          _summary = const OsSummary();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthController().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  Future<void> _abrirDadosPessoais() async {
    if (_usuario == null) return;
    final u = await Navigator.of(context).push<Usuario>(
      MaterialPageRoute(
        builder: (_) => ProfileEditView(usuario: _usuario!),
      ),
    );
    if (u != null && mounted) setState(() => _usuario = u);
  }

  void _abrirNotificacoes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsView()),
    );
  }

  Future<void> _abrirApariencia() async {
    final tc = GetIt.I<ThemeController>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Aparência',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _ThemeTile(
                  title: 'Modo claro',
                  subtitle: 'Fundo claro, melhor luz do dia',
                  value: ThemeMode.light,
                  group: tc.mode,
                ),
                const SizedBox(height: 6),
                _ThemeTile(
                  title: 'Modo escuro',
                  subtitle: 'Fundo escuro, menos cansaço à noite',
                  value: ThemeMode.dark,
                  group: tc.mode,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _usuario == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final stats = [
      _Stat('OS no mês', '${_summary.total}'),
      _Stat('Faturamento', _kfmt(_summary.totalValue)),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppBarCustom(title: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _HeaderCard(
            usuario: _usuario!,
            storage: GetIt.I<StorageService>(),
            connectivity: GetIt.I<ConnectivityService>(),
            onEditPhoto: _abrirDadosPessoais,
          ),
          const SizedBox(height: 20),
          _StatsCard(stats: stats),
          const SizedBox(height: 20),
          _Section(
            title: 'Conta',
            items: [
              _Item(
                icon: Icons.person_outline,
                label: 'Dados pessoais',
                hint: 'Nome, e-mail, telefone, foto',
                onTap: _abrirDadosPessoais,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Preferências',
            items: [
              _Item(
                icon: Icons.notifications_outlined,
                label: 'Notificações',
                hint: 'Abrir tela de alertas',
                onTap: _abrirNotificacoes,
              ),
              _Item(
                icon: Icons.dark_mode_outlined,
                label: 'Aparência',
                hint: 'Modo claro ou escuro',
                onTap: _abrirApariencia,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Sobre',
            items: [
              _Item(
                icon: Icons.settings_outlined,
                label: 'Sobre o app',
                hint: 'v1.0.0 (build 1)',
                onTap: () => showFeedback('ServiceFlow v1.0.0 build 1'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dangerLine, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 16, color: AppColors.dangerFg),
                  SizedBox(width: 8),
                  Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: AppColors.dangerFg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _kfmt(double v) {
    if (v >= 1000) {
      return 'R\$ ${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return fmtBRL(v);
  }
}

class _HeaderCard extends StatelessWidget {
  final Usuario usuario;
  final StorageService storage;
  final ConnectivityService connectivity;
  final VoidCallback onEditPhoto;

  const _HeaderCard({
    required this.usuario,
    required this.storage,
    required this.connectivity,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            offset: Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onEditPhoto,
            borderRadius: BorderRadius.circular(40),
            child: _HeaderAvatar(
              iniciais: usuario.iniciais,
              storageKey: usuario.avatarUrl,
              localFilePath: usuario.avatarPendentePath,
              storage: storage,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (usuario.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    usuario.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: connectivity.isOnline,
                  builder: (_, online, __) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Dot(
                            color: online
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                            size: 6,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            online ? 'Online' : 'Sem conexão',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final String iniciais;
  final String? storageKey;
  /// Foto nova ainda só no aparelho.
  final String? localFilePath;
  final StorageService storage;

  const _HeaderAvatar({
    required this.iniciais,
    required this.storageKey,
    required this.localFilePath,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final local = localFilePath;
    if (local != null && local.isNotEmpty) {
      final f = File(local);
      if (f.existsSync()) {
        return Image.file(
          f,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iniciais(),
        );
      }
    }
    if (storageKey == null || storageKey!.isEmpty) {
      return _iniciais();
    }
    return FutureBuilder<String?>(
      future: storage.signedUrlForProfile(storageKey),
      builder: (_, snap) {
        final url = snap.data;
        if (url == null) return _iniciais();
        return Image.network(
          url,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iniciais(),
        );
      },
    );
  }

  Widget _iniciais() {
    return Center(
      child: Text(
        iniciais,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title, subtitle;
  final ThemeMode value, group;
  const _ThemeTile(
      {required this.title, required this.subtitle, required this.value, required this.group});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return ListTile(
      onTap: () {
        GetIt.I<ThemeController>().setMode(value);
        Navigator.of(context).pop();
      },
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : const SizedBox(width: 20),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Stat {
  final String label, value;
  _Stat(this.label, this.value);
}

class _StatsCard extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[i].value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (i < stats.length - 1)
              Container(width: 1, height: 32, color: AppColors.borderSoft),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(height: 1, color: AppColors.borderSoft),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text)),
                  Text(hint,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
