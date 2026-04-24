import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_view.dart';
import '../../client/views/client_form_view.dart';
import '../../client/views/client_list_view.dart';
import '../../service_order/models/ordem_servico.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatefulWidget {
  final void Function(String filter) onOpenList;
  final VoidCallback onNewOS;
  final VoidCallback onOpenProfile;

  const DashboardView({
    super.key,
    required this.onOpenList,
    required this.onNewOS,
    required this.onOpenProfile,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with UiFeedbackMixin {
  late final DashboardController _ctrl = DashboardController();
  late final OfflineSyncService _sync = GetIt.I<OfflineSyncService>();

  @override
  void initState() {
    super.initState();
    _ctrl.load();
    _sync.lastStatus.addListener(_onSyncMsg);
  }

  void _onSyncMsg() {
    if (mounted) _ctrl.load();
  }

  @override
  void dispose() {
    _sync.lastStatus.removeListener(_onSyncMsg);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthController().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: Consumer<DashboardController>(
        builder: (_, c, __) {
          return RefreshIndicator(
            onRefresh: () async {
              await _sync.syncAll();
              await c.load();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (c.inFlight)
                  LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: AppColors.borderSoft,
                    color: AppColors.primary,
                  ),
                _Header(
                  nome: c.usuario?.nome ?? 'Bem-vindo',
                  iniciais: c.usuario?.iniciais ?? 'SF',
                  onProfile: widget.onOpenProfile,
                  onBell: () => widget.onOpenList('total'),
                  onLogout: _logout,
                ),
                _FaturamentoCard(summary: c.summary),
                const SectionHeader(title: 'Indicadores'),
                _KpiGrid(
                  summary: c.summary,
                  onTap: widget.onOpenList,
                ),
                const SectionHeader(title: 'Atalhos'),
                _Atalhos(
                  onNewOS: widget.onNewOS,
                  onNewClient: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClientFormView()),
                    );
                    c.load();
                  },
                  onClientList: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientListView(),
                      ),
                    );
                  },
                ),
                SectionHeader(
                  title: 'Ordens recentes',
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 28),
                    ),
                    onPressed: () => widget.onOpenList('total'),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                _RecentList(items: c.osList.take(3).toList()),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Saudação com base no relógio local (5h–12h: bom dia; 12h–18h: boa tarde; resto: boa noite).
String _saudacaoPorHora() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Bom dia';
  if (h >= 12 && h < 18) return 'Boa tarde';
  return 'Boa noite';
}

// ============================================================
class _Header extends StatelessWidget {
  final String nome;
  final String iniciais;
  final VoidCallback onProfile;
  final VoidCallback onBell;
  final VoidCallback onLogout;

  const _Header({
    required this.nome,
    required this.iniciais,
    required this.onProfile,
    required this.onBell,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfile,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    iniciais,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${_saudacaoPorHora().toLowerCase()}',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    nome,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            _CircleAction(icon: Icons.notifications_outlined, onTap: onBell),
            const SizedBox(width: 8),
            _CircleAction(icon: Icons.logout_rounded, onTap: onLogout),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Icon(icon, size: 18, color: AppColors.text),
      ),
    );
  }
}

// ============================================================
class _FaturamentoCard extends StatelessWidget {
  final OsSummary summary;
  const _FaturamentoCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FATURAMENTO · ABRIL',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmtBRL(summary.totalValue),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.executada} OS faturadas · ${summary.execucao + summary.aberto} em andamento',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _KpiGrid extends StatelessWidget {
  final OsSummary summary;
  final void Function(String) onTap;
  const _KpiGrid({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Kpi('total', 'Total', Icons.work_outline_rounded,
          summary.total, summary.totalValue, _Sem.neutral),
      _Kpi('aberto', 'Em aberto', Icons.access_time_rounded,
          summary.aberto, summary.abertoValue, _Sem.neutral),
      _Kpi('execucao', 'Em execução', Icons.edit_outlined,
          summary.execucao, summary.execucaoValue, _Sem.warning),
      _Kpi('executada', 'Executada', Icons.check_circle_outline,
          summary.executada, summary.executadaValue, _Sem.success),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: cards.map((c) => _KpiCard(kpi: c, onTap: () => onTap(c.key))).toList(),
      ),
    );
  }
}

enum _Sem { success, warning, neutral }

class _Kpi {
  final String key, label;
  final IconData icon;
  final int count;
  final double value;
  final _Sem sem;
  _Kpi(this.key, this.label, this.icon, this.count, this.value, this.sem);
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  final VoidCallback onTap;
  const _KpiCard({required this.kpi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, line) = switch (kpi.sem) {
      _Sem.success => (AppColors.successBg, AppColors.successFg, AppColors.successLine),
      _Sem.warning => (AppColors.warningBg, AppColors.warningFg, AppColors.warningLine),
      _Sem.neutral => (AppColors.tint, AppColors.primary, AppColors.borderSoft),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: line),
                  ),
                  child: Icon(kpi.icon, color: fg, size: 16),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textFaint),
              ],
            ),
            const Spacer(),
            Text(
              kpi.label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${kpi.count}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSoft, width: 1),
                ),
              ),
              child: Text(
                fmtBRL(kpi.value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _Atalhos extends StatelessWidget {
  final VoidCallback onNewOS;
  final VoidCallback onNewClient;
  final VoidCallback onClientList;
  const _Atalhos({
    required this.onNewOS,
    required this.onNewClient,
    required this.onClientList,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
          Expanded(
            child: InkWell(
              onTap: onNewOS,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      offset: Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova OS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('Registrar serviço',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onNewClient,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Novo cliente',
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('Cadastrar contato',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onClientList,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus clientes',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Listar, editar ou excluir cadastros',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
class _RecentList extends StatelessWidget {
  final List<OrdemServico> items;
  const _RecentList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.work_outline, color: AppColors.textFaint, size: 32),
              SizedBox(height: 8),
              Text('Nenhuma OS registrada ainda.',
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _RecentItem(os: items[i]),
            if (i < items.length - 1)
              Divider(height: 1, color: AppColors.borderSoft),
          ],
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final OrdemServico os;
  const _RecentItem({required this.os});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.borderSoft, width: 1),
              ),
            ),
            child: Text(
              os.codigo,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  os.clienteNome ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  os.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtBRL(os.valor),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(status: os.osStatus, small: true),
            ],
          ),
        ],
      ),
    );
  }
}
