import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/perfil_cache_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_state_store.dart';
import '../models/usuario.dart';

/// Repositório de autenticação — usa Supabase Auth + flutter_secure_storage
/// para o refresh-token e [PerfilCacheService] para o perfil offline.
class AuthRepository {
  static const _kTokenKey = 'sf.session.token';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _cache = PerfilCacheService.instance;

  SupabaseClient get _client => Supabase.instance.client;

  static const _kProfileFetchTimeout = Duration(seconds: 5);

  bool get _isOnline => GetIt.I<ConnectivityService>().isOnline.value;

  Usuario _usuarioMinimo(User user) {
    return Usuario(
      remoteId: user.id,
      localUuid: user.id,
      nome: user.email?.split('@').first ?? 'Usuário',
      email: user.email ?? '',
    );
  }

  /// Busca o perfil no Supabase, grava no SQLite e devolve, ou `null` em falha.
  Future<Usuario?> _fetchAndCache(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(_kProfileFetchTimeout);
      if (row == null) {
        final u = _usuarioMinimo(_client.auth.currentUser!);
        await _cache.upsert(
          u,
          markPending: false,
        );
        return u;
      }
      final u = Usuario.fromJson(row);
      await _cache.upsert(u, markPending: false);
      return u;
    } catch (_) {
      return null;
    }
  }

  Future<Usuario?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final cached = await _cache.load(user.id);
    if (cached != null && await _cache.hasPending(user.id)) {
      return cached;
    }

    // Sem internet: nunca abre HTTP (evita vários segundos de "carregando").
    if (!_isOnline) {
      if (cached != null) {
        return cached;
      }
      final minU = _usuarioMinimo(user);
      await _cache.upsert(minU, markPending: false);
      return minU;
    }

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_kProfileFetchTimeout);
      if (row != null) {
        final u = Usuario.fromJson(row);
        await _cache.upsert(u, markPending: false);
        return u;
      }
      if (cached != null) {
        return cached;
      }
      final minU = _usuarioMinimo(user);
      await _cache.upsert(minU, markPending: false);
      return minU;
    } on TimeoutException {
      if (cached != null) return cached;
      final minU = _usuarioMinimo(user);
      await _cache.upsert(minU, markPending: false);
      return minU;
    } catch (_) {
      if (cached != null) return cached;
      final minU = _usuarioMinimo(user);
      await _cache.upsert(minU, markPending: false);
      return minU;
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
    final u = Usuario(
      remoteId: res.user!.id,
      localUuid: res.user!.id,
      nome: nome,
      email: email,
      telefone: telefone,
    );
    await _cache.upsert(u, markPending: false);
    return u;
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Atualiza o perfil no Supabase quando online; só no SQLite se offline
  /// ([profile_pending_sync] = 1) para envio com [sincronizarPerfilPendente].
  ///
  /// [pendingAvatarPathLocal] — ficheiro copiado no disco (foto a enviar após
  /// voltar online). Ignorado com rede.
  Future<Usuario> updateProfile({
    required String nome,
    required String email,
    required String telefone,
    String? avatarUrl,
    bool clearAvatar = false,
    String? pendingAvatarPathLocal,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Não autenticado');
    }

    final emailTrim = email.trim();
    final nomeT = nome.trim();
    final telT = telefone.trim();
    final base = await _cache.load(user.id) ?? _usuarioMinimo(user);
    if (_isOnline) {
      if (emailTrim.isNotEmpty && emailTrim != user.email) {
        await _client.auth.updateUser(UserAttributes(email: emailTrim));
      }
      final map = <String, dynamic>{
        'nome': nomeT,
        'email': emailTrim,
        'telefone': telT,
      };
      if (clearAvatar) {
        map['avatar_url'] = null;
      } else if (avatarUrl != null) {
        map['avatar_url'] = avatarUrl;
      }
      await _client.from('profiles').update(map).eq('id', user.id);
      final u = await _fetchAndCache(user.id);
      if (u == null) {
        final fallback = await currentUser();
        if (fallback != null) return fallback;
        throw Exception('Não foi possível recarregar o perfil.');
      }
      return u;
    }

    // —— Offline: só persiste no SQLite. ——
    final newLocalPend = clearAvatar
        ? null
        : (pendingAvatarPathLocal ?? base.avatarPendentePath);
    String? avRemote = base.avatarUrl;
    if (clearAvatar) {
      avRemote = null;
    } else if (avatarUrl != null) {
      avRemote = avatarUrl;
    } else if (newLocalPend != null) {
      avRemote = base.avatarUrl;
    }

    final u = Usuario(
      remoteId: user.id,
      localUuid: user.id,
      nome: nomeT,
      email: emailTrim,
      telefone: telT.isNotEmpty ? telT : null,
      empresa: base.empresa,
      cargo: base.cargo,
      avaliacao: base.avaliacao,
      avatarUrl: avRemote,
      avatarPendentePath: newLocalPend,
    );
    await _cache.upsert(
      u,
      markPending: true,
      avatarLocalPendingPath: newLocalPend,
      avatarRemovePending: clearAvatar,
    );
    return u;
  }

  /// Envia alterações pendentes do perfil (após conectividade) — chamado pelo
  /// [OfflineSyncService].
  Future<void> sincronizarPerfilPendente() async {
    if (!_isOnline) return;
    final user = _client.auth.currentUser;
    if (user == null) return;

    final st = await _cache.loadPendenteEnvio(user.id);
    if (st == null) return;

    final s = st.user;
    final storage = GetIt.I<StorageService>();
    String? chave = s.avatarUrl;

    if (st.removeAvatar) {
      if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty) {
        await storage.removeProfileObject(s.avatarUrl);
      }
      if (s.avatarPendentePath != null) {
        try {
          final f = File(s.avatarPendentePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      chave = null;
    } else if (s.avatarPendentePath != null) {
      final f = File(s.avatarPendentePath!);
      if (await f.exists()) {
        if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty) {
          await storage.removeProfileObject(s.avatarUrl);
        }
        final k = await storage.uploadProfilePhoto(s.avatarPendentePath!);
        chave = k ?? s.avatarUrl;
        try {
          await f.delete();
        } catch (_) {}
      }
    }

    await _client.from('profiles').update({
      'nome': s.nome,
      'email': s.email,
      'telefone': s.telefone,
      'avatar_url': chave,
    }).eq('id', user.id);

    await _fetchAndCache(user.id);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    await _storage.delete(key: _kTokenKey);
    await SyncStateStore.instance.clearAll();
    await DatabaseHelper.instance.wipe();
  }
}
