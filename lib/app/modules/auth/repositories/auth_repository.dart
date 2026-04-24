import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/database_helper.dart';
import '../../../core/services/sync_state_store.dart';
import '../models/usuario.dart';

/// Repositório de autenticação — usa Supabase Auth + flutter_secure_storage
/// para persistir o refresh-token (RF01).
class AuthRepository {
  static const _kTokenKey = 'sf.session.token';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SupabaseClient get _client => Supabase.instance.client;

  /// Limite para buscar `profiles` — sem rede o HTTP pode ficar pendente minutos.
  static const _kProfileFetchTimeout = Duration(seconds: 5);

  Usuario _usuarioMinimo(User user) {
    return Usuario(
      remoteId: user.id,
      localUuid: user.id,
      nome: user.email?.split('@').first ?? 'Usuário',
      email: user.email ?? '',
    );
  }

  Future<Usuario?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_kProfileFetchTimeout);
      if (row == null) {
        return _usuarioMinimo(user);
      }
      return Usuario.fromJson(row);
    } on TimeoutException {
      return _usuarioMinimo(user);
    } catch (_) {
      return _usuarioMinimo(user);
    }
  }

  Future<Usuario> login(String email, String senha) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: senha,
    );
    if (res.user == null) {
      throw Exception('Não foi possível autenticar.');
    }
    if (res.session != null) {
      await _storage.write(key: _kTokenKey, value: res.session!.refreshToken);
    }
    final u = await currentUser();
    return u!;
  }

  Future<Usuario> signup({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: senha,
      data: {
        'nome': nome,
        'telefone': telefone,
      },
    );
    if (res.user == null) {
      throw Exception('Não foi possível criar a conta.');
    }
    return Usuario(
      remoteId: res.user!.id,
      localUuid: res.user!.id,
      nome: nome,
      email: email,
      telefone: telefone,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Atualiza `profiles` e, se necessário, o e-mail em `auth.users`.
  Future<Usuario> updateProfile({
    required String nome,
    required String email,
    required String telefone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Não autenticado');
    }

    final emailTrim = email.trim();
    if (emailTrim.isNotEmpty && emailTrim != user.email) {
      await _client.auth.updateUser(UserAttributes(email: emailTrim));
    }

    final map = <String, dynamic>{
      'nome': nome.trim(),
      'email': emailTrim,
      'telefone': telefone.trim(),
    };
    if (clearAvatar) {
      map['avatar_url'] = null;
    } else if (avatarUrl != null) {
      map['avatar_url'] = avatarUrl;
    }

    await _client.from('profiles').update(map).eq('id', user.id);

    final u = await currentUser();
    if (u == null) {
      throw Exception('Não foi possível recarregar o perfil.');
    }
    return u;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    await _storage.delete(key: _kTokenKey);
    // Limpa dados locais e cursores de sync — proteção contra "vazamento"
    // se outro usuário logar nesta mesma instalação.
    await SyncStateStore.instance.clearAll();
    await DatabaseHelper.instance.wipe();
  }
}
