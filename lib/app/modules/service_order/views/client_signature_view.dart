// Assinatura em tela cheia (paisagem); devolve PNG.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class ClientSignatureView extends StatefulWidget {
  const ClientSignatureView({super.key});

  @override
  State<ClientSignatureView> createState() => _ClientSignatureViewState();
}

class _ClientSignatureViewState extends State<ClientSignatureView>
    with UiFeedbackMixin {
  late final SignatureController _ctrl = SignatureController(
    penStrokeWidth: 2.5,
    penColor: AppColors.text,
    exportBackgroundColor: Colors.white,
  );

  bool _saving = false;
  /// Se false, mostra só o botão do olho.
  bool _controlesVisiveis = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onSig);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _onSig() => setState(() {});

  @override
  void dispose() {
    _ctrl.removeListener(_onSig);
    _ctrl.dispose();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _fechar() {
    Navigator.of(context).pop<Uint8List?>(null);
  }

  Future<void> _limpar() async {
    _ctrl.clear();
  }

  Future<void> _salvar() async {
    if (_ctrl.isEmpty) {
      showFeedback('Assine com o dedo em destaque', kind: FeedbackKind.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final Uint8List? bytes = await _ctrl.toPngBytes();
      if (bytes == null) {
        if (mounted) {
          showFeedback('Não foi possível exportar a assinatura.',
              kind: FeedbackKind.error);
        }
        return;
      }
      if (mounted) Navigator.of(context).pop<Uint8List>(bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleControles() {
    setState(() => _controlesVisiveis = !_controlesVisiveis);
  }

  @override
  Widget build(BuildContext context) {
    const acoesW = 140.0;
    const fabBg = 0.94;
    // Espaço para o olho não cobrir Limpar/Salvar.
    const kReservaOlho = 72.0;

    Widget olhoAcoes = Material(
      color: AppColors.surface.withValues(alpha: fabBg),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: IconButton(
        tooltip: _controlesVisiveis
            ? 'Ocultar botões (mais área para assinar)'
            : 'Mostrar botões',
        onPressed: _saving ? null : _toggleControles,
        icon: Icon(
          _controlesVisiveis
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.text,
        ),
        iconSize: 26,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Área de assinatura por baixo do resto.
          Material(
            color: AppColors.surface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Signature(
                  controller: _ctrl,
                  backgroundColor: AppColors.surface,
                ),
                if (_ctrl.isEmpty)
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Toque e deslize com o dedo para assinar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_controlesVisiveis) ...[
            Positioned(
              left: 6,
              top: 4,
              child: SafeArea(
                child: Material(
                  color: AppColors.surface.withValues(alpha: fabBg),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    padding: const EdgeInsets.all(10),
                    icon: Icon(
                      Icons.close,
                      size: 26,
                      color: AppColors.text,
                    ),
                    tooltip: 'Fechar',
                    onPressed: _saving ? null : _fechar,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 4,
              bottom: kReservaOlho,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: AppColors.surface.withValues(alpha: fabBg),
                    elevation: 3,
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: acoesW),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: acoesW,
                              child: OutlinedButton(
                                onPressed: _saving ? null : _limpar,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.text,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  side: BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Limpar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomButton(
                              fullWidth: true,
                              label: _saving ? 'Salvando...' : 'Salvar',
                              icon: _saving ? null : Icons.check_rounded,
                              loading: _saving,
                              onPressed: _saving ? null : _salvar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Olho fixo no canto inferior direito.
          Positioned(
            right: 6,
            bottom: 4,
            child: SafeArea(
              child: olhoAcoes,
            ),
          ),
        ],
      ),
    );
  }
}
