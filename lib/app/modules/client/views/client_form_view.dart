// Novo ou editar cliente: nome, doc e contatos.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/mixins/validator_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/view_insets.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';

class ClientFormView extends StatefulWidget {
  /// Se vier preenchido, abre em modo edição.
  final Cliente? cliente;

  const ClientFormView({super.key, this.cliente});

  @override
  State<ClientFormView> createState() => _ClientFormViewState();
}

class _ClientFormViewState extends State<ClientFormView>
    with UiFeedbackMixin, ValidatorMixin {
  final _nome = TextEditingController();
  final _doc = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  String? _eNome, _eDoc, _eEmail, _eTelefone;
  bool _loading = false;

  late final ClienteRepository _repo = GetIt.I<ClienteRepository>();

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nome.text = c.nome;
      if (c.doc != null) _doc.text = c.doc!;
      if (c.email != null) _email.text = c.email!;
      if (c.telefone != null) _telefone.text = c.telefone!;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _doc.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _eNome = validateRequired(_nome.text, label: 'Nome');
      _eDoc = validateCpfCnpj(_doc.text);
      _eEmail = validateEmail(_email.text);
      _eTelefone = validatePhone(_telefone.text);
    });
    if ([_eNome, _eDoc, _eEmail, _eTelefone].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      if (widget.cliente != null) {
        final antes = widget.cliente!;
        final salvo = await _repo.atualizar(
          antes.copyWith(
            nome: _nome.text.trim(),
            doc: _doc.text.trim(),
            email: _email.text.trim(),
            telefone: _telefone.text.trim(),
          ),
        );
        if (!mounted) return;
        showFeedback('Cliente atualizado', kind: FeedbackKind.success);
        Navigator.of(context).pop<Cliente>(salvo);
      } else {
        final c = Cliente(
          nome: _nome.text.trim(),
          doc: _doc.text.trim(),
          email: _email.text.trim(),
          telefone: _telefone.text.trim(),
        );
        final salvo = await _repo.criar(c);
        if (!mounted) return;
        showFeedback('Cliente cadastrado com sucesso',
            kind: FeedbackKind.success);
        Navigator.of(context).pop<Cliente>(salvo);
      }
    } catch (e) {
      if (!mounted) return;
      if (widget.cliente != null) {
        showFeedback('Não foi possível salvar. Tente de novo.',
            kind: FeedbackKind.error);
      } else {
        showFeedback('Salvo localmente — sincronizaremos quando voltar online.',
            kind: FeedbackKind.warning);
        Navigator.of(context).pop<Cliente?>(null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBarCustom(
        title: widget.cliente == null ? 'Novo cliente' : 'Editar cliente',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 40 + viewBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dados do cliente',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text)),
                    Text('Vincule OS a este cadastro depois.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Nome / Razão social',
              icon: Icons.business_outlined,
              placeholder: 'Ex: Indústrias Bravo Ltda.',
              controller: _nome,
              errorText: _eNome,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'CPF / CNPJ',
              icon: Icons.badge_outlined,
              placeholder: '000.000.000-00',
              controller: _doc,
              keyboardType: TextInputType.number,
              inputFormatters: [CpfCnpjFormatter()],
              errorText: _eDoc,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'E-mail',
              icon: Icons.mail_outline,
              placeholder: 'contato@empresa.com',
              keyboardType: TextInputType.emailAddress,
              controller: _email,
              errorText: _eEmail,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Telefone',
              icon: Icons.phone_outlined,
              placeholder: '(11) 98888-7777',
              controller: _telefone,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneFormatter()],
              errorText: _eTelefone,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Cancelar',
                    variant: CustomButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    label: 'Salvar',
                    icon: Icons.check_rounded,
                    loading: _loading,
                    onPressed: _loading ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
