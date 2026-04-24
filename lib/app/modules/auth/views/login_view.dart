import 'package:flutter/material.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/mixins/validator_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';
import 'signup_view.dart';
import '../../dashboard/views/main_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with UiFeedbackMixin, ValidatorMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passError;
  late final AuthController _auth = AuthController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailE = validateEmail(_email.text);
    final passE = validatePassword(_pass.text);
    setState(() {
      _emailError = emailE;
      _passError = passE;
    });
    if (emailE != null || passE != null) return;

    setState(() => _loading = true);
    try {
      final user = await _auth.login(_email.text, _pass.text);
      if (!mounted) return;
      showFeedback('Bem-vindo de volta, ${user.nome.split(' ').first}',
          kind: FeedbackKind.success);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showFeedback(_friendly(e), kind: FeedbackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid login') || s.contains('credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (s.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (s.contains('socket') || s.contains('failed host')) {
      return 'Sem conexão. Verifique sua internet.';
    }
    return 'Não foi possível entrar. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                Center(child: AppLogo(size: 72)),
                const SizedBox(height: 28),
                Text(
                  'Bem-vindo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entre na sua conta para continuar.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                CustomTextField(
                  label: 'E-mail',
                  placeholder: 'voce@empresa.com',
                  controller: _email,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Senha',
                  placeholder: '••••••••',
                  controller: _pass,
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  errorText: _passError,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 32),
                    ),
                    onPressed: () async {
                      if (validateEmail(_email.text) != null) {
                        showFeedback('Informe seu e-mail para receber o link.',
                            kind: FeedbackKind.warning);
                        return;
                      }
                      try {
                        await _auth.sendPasswordReset(_email.text);
                        showFeedback('Link de redefinição enviado por e-mail.',
                            kind: FeedbackKind.success);
                      } catch (_) {
                        showFeedback('Não foi possível enviar o link agora.',
                            kind: FeedbackKind.error);
                      }
                    },
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  label: 'Entrar',
                  onPressed: _loading ? null : _submit,
                  loading: _loading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.borderSoft)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.borderSoft)),
                  ],
                ),
                const SizedBox(height: 14),
                CustomButton(
                  label: 'Criar nova conta',
                  variant: CustomButtonVariant.secondary,
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupView()),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'ServiceFlow · v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textFaint,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
