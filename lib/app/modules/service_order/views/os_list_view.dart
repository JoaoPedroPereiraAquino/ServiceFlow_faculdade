// Lista OS do aparelho, filtra e abre o detalhe.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/ordem_servico.dart';
import '../repositories/ordem_servico_repository.dart';
import 'os_detail_view.dart';

class OsListView extends StatefulWidget {
  final String initialFilter;
  const OsListView({super.key, this.initialFilter = 'total'});

  @override
  State<OsListView> createState() => _OsListViewState();
}

class _OsListViewState extends State<OsListView> {
  late final OrdemServicoRepository _repo = GetIt.I<OrdemServicoRepository>();
  late final OfflineSyncService _sync = GetIt.I<OfflineSyncService>();

  List<OrdemServico> _all = [];
  String _filter = 'total';
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listarTodas();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  Future<void> _abrirDetalhe(OrdemServico os) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OsDetailView(ordemInicial: os)),
    );
    if (mounted) await _load();
  }

  List<OrdemServico> get _filtered {
    Iterable<OrdemServico> list = _all;
    switch (_filter) {
      case 'aberto':
        list = list.where((o) => o.osStatus == OsStatus.aberto);
        break;
      case 'execucao':
        list = list.where((o) => o.osStatus == OsStatus.execucao);
        break;
      case 'executada':
        list = list.where((o) => o.osStatus == OsStatus.executada);
        break;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((o) =>
          o.codigo.toLowerCase().contains(q) ||
          o.descricao.toLowerCase().contains(q) ||
          (o.clienteNome ?? '').toLowerCase().contains(q));
    }
    return list.toList();
  }

  int _count(String key) {
    switch (key) {
      case 'aberto':
        return _all.where((o) => o.osStatus == OsStatus.aberto).length;
      case 'execucao':
        return _all.where((o) => o.osStatus == OsStatus.execucao).length;
      case 'executada':
        return _all.where((o) => o.osStatus == OsStatus.executada).length;
      default:
        return _all.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalValue = filtered.fold<double>(0, (a, b) => a + b.valor);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarCustom(
        title: 'Ordens de serviço',
        subtitle: '${filtered.length} resultados · ${fmtBRL(totalValue)}',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sync.syncAll();
          await _load();
        },
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _ChipsBar(
                    current: _filter,
                    onChange: (k) => setState(() => _filter = k),
                    counts: {
                      'total': _count('total'),
                      'aberto': _count('aberto'),
                      'execucao': _count('execucao'),
                      'executada': _count('executada'),
                    },
                  ),
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: CustomTextField(
                      placeholder: 'Buscar por cliente, ID ou descrição',
                      icon: Icons.search,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const _Empty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _OsCard(
                              os: filtered[i],
                              onTap: () => _abrirDetalhe(filtered[i]),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChipsBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChange;
  final Map<String, int> counts;

  const _ChipsBar({
    required this.current,
    required this.onChange,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('total', 'Todas'),
      ('aberto', 'Em aberto'),
      ('execucao', 'Em execução'),
      ('executada', 'Executada'),
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final it in items) ...[
              _Chip(
                label: it.$2,
                count: counts[it.$1] ?? 0,
                active: current == it.$1,
                onTap: () => onChange(it.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.borderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
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

class _OsCard extends StatelessWidget {
  final OrdemServico os;
  final VoidCallback onTap;
  const _OsCard({required this.os, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                os.codigo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              StatusBadge(status: os.osStatus, small: true),
              if (os.status == 'P') ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Pendente de sincronização',
                  child: Icon(Icons.cloud_off_outlined,
                      size: 14, color: AppColors.warningFg),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (os.clienteNome != null && os.clienteNome!.trim().isNotEmpty)
                ? os.clienteNome!
                : 'Cliente',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            os.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderSoft, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  os.createdAt != null
                      ? fmtRelative(os.createdAt!)
                      : '',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  fmtBRL(os.valor),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.work_outline_rounded, size: 36, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text('Nenhuma OS encontrada',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
