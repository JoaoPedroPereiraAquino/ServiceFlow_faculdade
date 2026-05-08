// Tela para criar uma OS: cliente, texto, valor, fotos e assinatura.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/mixins/validator_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/view_insets.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/evidence_image.dart';
import '../../../shared/widgets/loader_overlay.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../client/models/cliente.dart';
import '../../client/repositories/cliente_repository.dart';
import '../../client/views/client_form_view.dart';
import '../models/ordem_servico.dart';
import '../repositories/ordem_servico_repository.dart';
import 'client_signature_view.dart';

class OsFormView extends StatefulWidget {
  const OsFormView({super.key});

  @override
  State<OsFormView> createState() => _OsFormViewState();
}

class _OsFormViewState extends State<OsFormView>
    with UiFeedbackMixin, ValidatorMixin {
  final _desc = TextEditingController();
  final _valor = TextEditingController();

  Cliente? _cliente;
  List<Cliente> _clientes = [];
  bool _dropdownOpen = false;

  String? _fotoAntesPath;
  String? _fotoDepoisPath;

  Uint8List? _assinaturaPng;

  String? _eCliente, _eDesc, _eValor, _eSig;
  bool _loading = false;

  late final OrdemServicoRepository _osRepo = GetIt.I<OrdemServicoRepository>();
  late final ClienteRepository _cliRepo = GetIt.I<ClienteRepository>();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final list = await _cliRepo.listarTodos();
    if (!mounted) return;
    setState(() => _clientes = list);
  }

  Future<void> _adicionarCliente() async {
    setState(() => _dropdownOpen = false);
    final result = await Navigator.of(context).push<Cliente?>(
      MaterialPageRoute(builder: (_) => const ClientFormView()),
    );
    if (!mounted) return;
    await _loadClientes();
    if (result == null) return;
    setState(() {
      final m = _clientes.where((c) => c.localUuid == result.localUuid).toList();
      _cliente = m.isNotEmpty ? m.first : result;
      _eCliente = null;
    });
  }

  Future<void> _abrirAssinatura() async {
    final bytes = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        builder: (_) => const ClientSignatureView(),
        fullscreenDialog: true,
      ),
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _assinaturaPng = bytes;
      _eSig = null;
    });
  }

  @override
  void dispose() {
    _desc.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _takePhoto({required bool antes}) async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (img == null) return;
      setState(() {
        if (antes) {
          _fotoAntesPath = img.path;
        } else {
          _fotoDepoisPath = img.path;
        }
      });
    } catch (_) {
      showFeedback('Não foi possível abrir a câmera.',
          kind: FeedbackKind.error);
    }
  }

  Future<void> _save() async {
    final valorNum = parseMoney(_valor.text);
    setState(() {
      _eCliente = _cliente == null ? 'Selecione um cliente' : null;
      _eDesc = validateMinLength(_desc.text, 10, label: 'Descrição');
      _eValor = valorNum <= 0 ? 'Informe um valor válido' : null;
      _eSig = _assinaturaPng == null ? 'Assinatura obrigatória do cliente' : null;
    });
    if ([_eCliente, _eDesc, _eValor, _eSig].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      String? sigB64;
      if (_assinaturaPng != null) {
        sigB64 = base64Encode(_assinaturaPng!);
      }

      final codigo = await _osRepo.proximoCodigo();
      final u = await GetIt.I<AuthRepository>().currentUser();
      final nomeTecnico =
          (u?.nome != null && u!.nome.trim().isNotEmpty) ? u.nome.trim() : '—';
      final os = OrdemServico(
        codigo: codigo,
        clienteLocalUuid: _cliente!.localUuid,
        clienteRemoteId: _cliente!.remoteId,
        clienteNome: _cliente!.nome,
        descricao: _desc.text.trim(),
        valor: valorNum,
        fotoAntesPath: _fotoAntesPath,
        fotoDepoisPath: _fotoDepoisPath,
        assinaturaBase64: sigB64,
        tecnico: nomeTecnico,
      );
      await _osRepo.criar(os);
      if (!mounted) return;
      showFeedback('OS registrada com sucesso',
          kind: FeedbackKind.success);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      showFeedback('Salva localmente — sincronizaremos depois.',
          kind: FeedbackKind.warning);
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = viewBottomInset(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppBarCustom(title: 'Nova ordem de serviço'),
      body: LoaderOverlay(
        show: _loading,
        text: 'Salvando OS...',
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 40 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClienteDropdown(
                clientes: _clientes,
                selecionado: _cliente,
                open: _dropdownOpen,
                onToggle: () =>
                    setState(() => _dropdownOpen = !_dropdownOpen),
                onSelect: (c) => setState(() {
                  _cliente = c;
                  _dropdownOpen = false;
                  _eCliente = null;
                }),
                onAddNew: _adicionarCliente,
                error: _eCliente,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Descrição do serviço',
                placeholder: 'Detalhe o que será executado...',
                controller: _desc,
                maxLines: 4,
                errorText: _eDesc,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Valor estipulado',
                icon: Icons.attach_money_rounded,
                placeholder: 'R\$ 0,00',
                controller: _valor,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyFormatter()],
                errorText: _eValor,
              ),
              const SizedBox(height: 16),
              const _Label('Evidências fotográficas'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSlot(
                      label: 'Foto antes',
                      filePath: _fotoAntesPath,
                      onTap: () => _takePhoto(antes: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoSlot(
                      label: 'Foto depois',
                      filePath: _fotoDepoisPath,
                      onTap: () => _takePhoto(antes: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AssinaturaSection(
                bytes: _assinaturaPng,
                error: _eSig,
                onAbrir: _abrirAssinatura,
                onTrocar: _abrirAssinatura,
                onLimpar: () {
                  setState(() {
                    _assinaturaPng = null;
                    _eSig = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: _loading ? 'Processando...' : 'Salvar OS',
                icon: _loading ? null : Icons.check_rounded,
                loading: _loading,
                onPressed: _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssinaturaSection extends StatelessWidget {
  final Uint8List? bytes;
  final String? error;
  final VoidCallback onAbrir;
  final VoidCallback onTrocar;
  final VoidCallback onLimpar;

  const _AssinaturaSection({
    required this.bytes,
    required this.error,
    required this.onAbrir,
    required this.onTrocar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final hasSig = bytes != null && bytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label('Assinatura do cliente', error: hasError),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: hasSig ? onTrocar : onAbrir,
          icon: Icon(
            hasSig ? Icons.draw_outlined : Icons.gesture_outlined,
            size: 20,
            color: hasError ? AppColors.dangerFg : AppColors.primary,
          ),
          label: Text(
            hasSig ? 'Trocar assinatura' : 'Toque para assinar',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: hasError ? AppColors.dangerFg : AppColors.primary,
            side: BorderSide(
              color: hasError ? AppColors.dangerFg : AppColors.primary,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: hasSig ? AppColors.tint : AppColors.surface,
          ),
        ),
        if (hasSig) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prévia',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onLimpar,
                child: Text('Remover', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 120,
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.memory(
              bytes!,
              fit: BoxFit.contain,
            ),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(error!,
              style: TextStyle(fontSize: 12, color: AppColors.dangerFg)),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool error;
  const _Label(this.text, {this.error = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: error ? AppColors.dangerFg : AppColors.textMuted,
      ),
    );
  }
}

Widget _osFormClienteListItem(
  Cliente c, {
  required Cliente? selecionado,
  required ValueChanged<Cliente> onSelect,
}) {
  final selected = selecionado?.localUuid == c.localUuid;
  return Material(
    color: selected ? AppColors.tint : AppColors.surface,
    child: InkWell(
      onTap: () => onSelect(c),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.nome,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            if (c.doc != null && c.doc!.isNotEmpty)
              Text(
                c.doc!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ClienteDropdown extends StatelessWidget {
  final List<Cliente> clientes;
  final Cliente? selecionado;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<Cliente> onSelect;
  final Future<void> Function() onAddNew;
  final String? error;

  const _ClienteDropdown({
    required this.clientes,
    required this.selecionado,
    required this.open,
    required this.onToggle,
    required this.onSelect,
    required this.onAddNew,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final borderColor = hasError
        ? AppColors.dangerFg
        : open
            ? AppColors.primary
            : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Cliente'),
        const SizedBox(height: 6),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selecionado?.nome ?? 'Selecione um cliente',
                    style: TextStyle(
                      color: selecionado != null
                          ? AppColors.text
                          : AppColors.textFaint,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: AppColors.surface,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Material(
                      color: AppColors.tint,
                      child: InkWell(
                        onTap: onAddNew,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Adicionar novo cliente',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (int i = 0; i < clientes.length; i++) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderSoft,
                      ),
                      _osFormClienteListItem(
                        clientes[i],
                        selecionado: selecionado,
                        onSelect: onSelect,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(error!,
              style: TextStyle(fontSize: 12, color: AppColors.dangerFg)),
        ],
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final String? filePath;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.label,
    required this.filePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = filePath != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: filled ? AppColors.surfaceAlt : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: filled
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: EvidenceImage(
                        localPath: filePath,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 22, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted)),
                  ],
                ),
        ),
      ),
    );
  }
}
