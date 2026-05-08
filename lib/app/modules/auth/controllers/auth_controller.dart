// Telas de login usam isto; por baixo vai a camada que fala com servidor e sessão.
import 'package:get_it/get_it.dart';

import '../models/usuario.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _repo = GetIt.I<AuthRepository>();

  Future<Usuario?> currentUser() => _repo.currentUser();

  Future<Usuario> login(String email, String senha) => _repo.login(email, senha);

  Future<Usuario> signup({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) {
    return _repo.signup(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
    );
  }

  Future<void> sendPasswordReset(String email) => _repo.sendPasswordReset(email);

  Future<void> logout() => _repo.logout();
}
