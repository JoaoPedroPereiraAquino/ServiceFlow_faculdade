// Detalhe da OS: fotos, assinatura, mudar status ou excluir.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/view_insets.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/evidence_image.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/ordem_servico.dart';
import '../repositories/ordem_servico_repository.dart';

class OsDetailView extends StatefulWidget {
  final OrdemServico ordemInicial;

  const OsDetailView({super.key, required this.ordemInicial});

  @override
  State<OsDetailView> createState() => _OsDetailViewState();
}

class _OsDetailViewState extends State<OsDetailView> with UiFeedbackMixin {
  late final OrdemServicoRepository _repo = GetIt.I<OrdemServicoRepository>();
  late final OfflineSyncService _sync = GetIt.I<OfflineSyncService>();

  late OrdemServico _os;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _os = widget.ordemInicial;
    _reload();
  }

  Future<void> _reload() async {
    final fresh = await _repo.getByLocalUuid(_os.localUuid);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _os = fresh;
      _loading = false;
    });
  }

  Future<void> _abrirStatus() async {
    OsStatus escolhido = _os.osStatus;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewPaddingOf(ctx).bottom,
            ),
            child: StatefulBuilder(
              builder: (ctx, setS) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _os.codigo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status da ordem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...OsStatus.values.map(
                      (s) => RadioListTile<OsStatus>(
                        value: s,
                        groupValue: escolhido,
                        onChanged: (v) {
                          if (v != null) setS(() => escolhido = v);
                        },
                        title: Text(s.label),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Aplicar status'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    if (escolhido == _os.osStatus) return;
    try {
      _os.osStatus = escolhido;
      await _repo.atualizar(_os);
      if (!mounted) return;
      showFeedback('Status atualizado', kind: FeedbackKind.success);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      showFeedback('Não foi possível salvar o status. Tente de novo.',
          kind: FeedbackKind.error);
    }
  }

  Future<void> _confirmarExcluir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ordem de serviço?'),
        content: Text(
          'A ordem ${_os.codigo} será removida deste aparelho.'
          '${_os.remoteId != null && _os.remoteId!.isNotEmpty ? ' Se já estiver sincronizada, também será removida do servidor.' : ''} '
          'Não é possível desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerFg),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.excluir(_os);
      if (!mounted) return;
      showFeedback('Ordem excluída', kind: FeedbackKind.success);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      showFeedback(
        'Não foi possível excluir. Verifique a conexão ou tente novamente.',
        kind: FeedbackKind.error,
      );
    }
  }

  Widget? _assinaturaWidget() {
    final b64 = _os.assinaturaBase64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      final bytes = base64Decode(b64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: 160,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (_) {
      return Text(
        'Assinatura indisponível',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const AppBarCustom(title: 'Ordem de serviço'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sig = _assinaturaWidget();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarCustom(
        title: _os.codigo,
        subtitle: _os.clienteNome ?? 'Cliente',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sync.syncAll();
          await _reload();
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            40 + viewBottomInset(context),
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _os.descricao,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: _os.osStatus, small: false),
              ],
            ),
            if (_os.status == 'P') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 16, color: AppColors.warningFg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pendente de sincronização',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warningFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _SectionLabel('Valor'),
            const SizedBox(height: 6),
            Text(
              fmtBRL(_os.valor),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 18),
            _SectionLabel('Técnico'),
            const SizedBox(height: 6),
            Text(
              _os.tecnico,
              style: TextStyle(fontSize: 14, color: AppColors.text),
            ),
            const SizedBox(height: 18),
            _SectionLabel('Registro'),
            const SizedBox(height: 6),
            Text(
              _os.createdAt != null
                  ? '${fmtDateShort(_os.createdAt!)} · ${fmtRelative(_os.createdAt!)}'
                  : '—',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Foto antes'),
            const SizedBox(height: 8),
            _EvidenceBox(
              child: EvidenceImage(
                localPath: _os.fotoAntesPath,
                remotePath: _os.fotoAntesRemotePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Foto depois'),
            const SizedBox(height: 8),
            _EvidenceBox(
              child: EvidenceImage(
                localPath: _os.fotoDepoisPath,
                remotePath: _os.fotoDepoisRemotePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Assinatura do cliente'),
            const SizedBox(height: 8),
            _EvidenceBox(
              child: sig ??
                  Text(
                    'Sem assinatura registrada',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _abrirStatus,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Alterar status'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _confirmarExcluir,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.dangerFg),
              label: Text(
                'Excluir ordem',
                style: TextStyle(
                  color: AppColors.dangerFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.dangerLine),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _EvidenceBox extends StatelessWidget {
  final Widget child;
  const _EvidenceBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
