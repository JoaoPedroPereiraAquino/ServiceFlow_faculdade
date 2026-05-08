// Cadastro com validação de campos e senha.
import 'package:flutter/material.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/mixins/validator_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/view_insets.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView>
    with UiFeedbackMixin, ValidatorMixin {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();

  String? _eNome, _eEmail, _eTelefone, _eSenha, _eConfirma;
  bool _obscure = true;
  bool _loading = false;
  late final AuthController _auth = AuthController();

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _eNome = validateMinLength(_nome.text, 3, label: 'Nome');
      _eEmail = validateEmail(_email.text);
      _eTelefone = validatePhone(_telefone.text);
      _eSenha = validatePassword(_senha.text);
      _eConfirma =
          _senha.text != _confirma.text ? 'Senhas não conferem' : null;
    });
    if ([_eNome, _eEmail, _eTelefone, _eSenha, _eConfirma]
        .any((e) => e != null)) {
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signup(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        telefone: _telefone.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
      showFeedback('Conta criada! Faça login para continuar.',
          kind: FeedbackKind.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final s = e.toString().toLowerCase();
      final friendly = s.contains('already') || s.contains('registered')
          ? 'Este e-mail já está cadastrado.'
          : 'Não foi possível criar a conta.';
      showFeedback(friendly, kind: FeedbackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppBarCustom(title: 'Criar conta'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 40 + viewBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preencha seus dados para começar a gerenciar ordens de serviço.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            CustomTextField(
              label: 'Nome completo',
              icon: Icons.person_outline,
              placeholder: 'Ana Souza',
              controller: _nome,
              errorText: _eNome,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'E-mail',
              icon: Icons.mail_outline,
              placeholder: 'ana@empresa.com',
              keyboardType: TextInputType.emailAddress,
              controller: _email,
              errorText: _eEmail,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Telefone',
              icon: Icons.phone_outlined,
              placeholder: '(11) 98888-7777',
              keyboardType: TextInputType.phone,
              controller: _telefone,
              inputFormatters: [PhoneFormatter()],
              errorText: _eTelefone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Senha',
              icon: Icons.lock_outline,
              placeholder: 'no mínimo 7 caracteres',
              controller: _senha,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              errorText: _eSenha,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirme a senha',
              icon: Icons.lock_outline,
              placeholder: 'repita a senha',
              controller: _confirma,
              obscure: _obscure,
              errorText: _eConfirma,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: 'Ao criar conta você concorda com os '),
                          TextSpan(
                            text: 'Termos de uso',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de privacidade',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' do ServiceFlow.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Criar conta',
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
