import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/mixins/validator_mixin.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/view_insets.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loader_overlay.dart';
import '../../auth/models/usuario.dart';
import '../../auth/repositories/auth_repository.dart';
import 'profile_avatar_picker.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key, required this.usuario});

  final Usuario usuario;

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView>
    with UiFeedbackMixin, ValidatorMixin {
  late final _nome = TextEditingController(text: widget.usuario.nome);
  late final _email = TextEditingController(text: widget.usuario.email);
  late final _telefone = TextEditingController(
    text: (widget.usuario.telefone ?? '').trim().isNotEmpty
        ? widget.usuario.telefone
        : '',
  );

  String? _eNome, _eTelefone;
  bool _loading = false;
  String? _localFotoPicked;
  bool _removerFoto = false;

  late final String? _fotoInicial;
  final _auth = GetIt.I<AuthRepository>();
  final _storage = GetIt.I<StorageService>();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fotoInicial = widget.usuario.avatarUrl;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  void _onRemoverFoto() {
    setState(() {
      _localFotoPicked = null;
      if (_fotoInicial != null) _removerFoto = true;
    });
  }

  Future<void> _pickFoto() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (img == null) return;
    setState(() {
      _localFotoPicked = img.path;
      _removerFoto = false;
    });
  }

  String get _emailBloqueado => widget.usuario.email;

  bool get _online => GetIt.I<ConnectivityService>().isOnline.value;

  /// Copia a foto escolhida para um ficheiro estável na app (envio com rede).
  Future<String?> _copiaFotoPendente(String src) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(
        dir.path, 'profile_pending_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(src).copy(dest);
    return dest;
  }

  Future<void> _save() async {
    setState(() {
      _eNome = validateMinLength(_nome.text, 2, label: 'Nome');
      _eTelefone = validatePhone(_telefone.text);
    });
    if ([_eNome, _eTelefone].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      if (_online) {
        if (_removerFoto) {
          if (_fotoInicial != null) {
            await _storage.removeProfileObject(_fotoInicial);
          }
          final u = await _auth.updateProfile(
            nome: _nome.text,
            email: _emailBloqueado,
            telefone: _telefone.text,
            clearAvatar: true,
          );
          if (mounted) {
            showFeedback('Dados salvos', kind: FeedbackKind.success);
            Navigator.of(context).pop<Usuario>(u);
          }
          return;
        }

        if (_localFotoPicked != null) {
          final chave = await _storage.uploadProfilePhoto(_localFotoPicked!);
          if (chave == null) {
            if (mounted) {
              showFeedback('Falha ao enviar a imagem', kind: FeedbackKind.error);
            }
            return;
          }
          if (_fotoInicial != null && _fotoInicial != chave) {
            await _storage.removeProfileObject(_fotoInicial);
          }
          final u = await _auth.updateProfile(
            nome: _nome.text,
            email: _emailBloqueado,
            telefone: _telefone.text,
            avatarUrl: chave,
          );
          if (mounted) {
            showFeedback('Dados salvos', kind: FeedbackKind.success);
            Navigator.of(context).pop<Usuario>(u);
          }
          return;
        }

        final u = await _auth.updateProfile(
          nome: _nome.text,
          email: _emailBloqueado,
          telefone: _telefone.text,
        );
        if (mounted) {
          showFeedback('Dados salvos', kind: FeedbackKind.success);
          Navigator.of(context).pop<Usuario>(u);
        }
        return;
      }

      // —— Sem internet: grava no SQLite; fotos pendentes sincronizam depois. ——
      String? localPend;
      if (_localFotoPicked != null) {
        try {
          localPend = await _copiaFotoPendente(_localFotoPicked!);
        } catch (_) {
          if (mounted) {
            showFeedback('Não foi possível guardar a imagem localmente.',
                kind: FeedbackKind.error);
          }
          return;
        }
      }
      final u = await _auth.updateProfile(
        nome: _nome.text,
        email: _emailBloqueado,
        telefone: _telefone.text,
        clearAvatar: _removerFoto,
        pendingAvatarPathLocal: localPend,
      );
      if (mounted) {
        showFeedback('Salvo no dispositivo. Sincronizaremos ao voltar a rede.',
            kind: FeedbackKind.success);
        Navigator.of(context).pop<Usuario>(u);
      }
    } catch (_) {
      if (mounted) {
        showFeedback('Não foi possível salvar. Tente de novo.',
            kind: FeedbackKind.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = viewBottomInset(context);
    final temFotoVisivel = !_removerFoto &&
        (_localFotoPicked != null || _fotoInicial != null);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppBarCustom(title: 'Dados pessoais'),
      body: LoaderOverlay(
        show: _loading,
        text: 'Salvando...',
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 32 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileAvatarPicker(
                iniciais: widget.usuario.iniciais,
                localFilePath: _removerFoto ? null : _localFotoPicked,
                storageKey: _removerFoto || _localFotoPicked != null
                    ? null
                    : _fotoInicial,
                showRemove: temFotoVisivel,
                onTrocar: _pickFoto,
                onRemover: temFotoVisivel ? _onRemoverFoto : null,
              ),
              const SizedBox(height: 8),
              Text(
                'O e-mail de acesso não pode ser alterado nesta tela.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Nome completo',
                icon: Icons.person_outline,
                controller: _nome,
                errorText: _eNome,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'E-mail',
                icon: Icons.mail_outline,
                controller: _email,
                readOnly: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Telefone',
                icon: Icons.phone_outlined,
                controller: _telefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneFormatter()],
                errorText: _eTelefone,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Salvar alterações',
                icon: Icons.check_rounded,
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
