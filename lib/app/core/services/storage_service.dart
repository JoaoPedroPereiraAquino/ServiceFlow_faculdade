import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Serviço de upload/download para o bucket privado `os-evidencias`.
///
/// Convenção do path remoto: `<userId>/ordens_servico/<localUuid>/<arquivo>`
/// — alinhado com a RLS, que só libera o usuário em sua pasta `<userId>/`.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String bucket = 'os-evidencias';
  static const String bucketPerfil = 'perfil-avatars';
  final _uuid = const Uuid();

  /// Faz upload do arquivo local para o bucket e devolve a *chave remota*
  /// (não a URL pública — o bucket é privado). Retorna `null` se não houver
  /// usuário autenticado ou se o arquivo não existir.
  Future<String?> uploadOsPhoto({
    required String localUuidOs,
    required String localFilePath,
    required String prefix,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final file = File(localFilePath);
    if (!await file.exists()) return null;

    final ext = p.extension(localFilePath).isEmpty
        ? '.jpg'
        : p.extension(localFilePath).toLowerCase();
    final fileName = '${prefix}_${_uuid.v4()}$ext';
    final remotePath = '${user.id}/ordens_servico/$localUuidOs/$fileName';

    final mimeType = _mimeForExt(ext);

    await Supabase.instance.client.storage.from(bucket).upload(
          remotePath,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    return remotePath;
  }

  static const _kSignedUrlTimeout = Duration(seconds: 8);

  /// Gera uma Signed URL válida por [expiresInSeconds] (default 1 hora) para
  /// permitir exibir a imagem no `Image.network`.
  Future<String?> signedUrlFor(String? remotePath,
      {int expiresInSeconds = 3600}) async {
    if (remotePath == null || remotePath.isEmpty) return null;
    try {
      return await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(remotePath, expiresInSeconds)
          .timeout(_kSignedUrlTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload de foto de perfil — path: `<userId>/avatar_<uuid>.<ext>`
  Future<String?> uploadProfilePhoto(String localFilePath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final file = File(localFilePath);
    if (!await file.exists()) return null;
    final ext = p.extension(localFilePath).isEmpty
        ? '.jpg'
        : p.extension(localFilePath).toLowerCase();
    final fileName = 'avatar_${_uuid.v4()}$ext';
    final remotePath = '${user.id}/$fileName';
    final mime = _mimeForExt(ext);
    await Supabase.instance.client.storage.from(bucketPerfil).upload(
          remotePath,
          file,
          fileOptions: FileOptions(
            contentType: mime,
            upsert: true,
          ),
        );
    return remotePath;
  }

  /// Signed URL do bucket de perfil.
  Future<String?> signedUrlForProfile(String? remotePath,
      {int expiresInSeconds = 3600}) async {
    if (remotePath == null || remotePath.isEmpty) return null;
    try {
      return await Supabase.instance.client.storage
          .from(bucketPerfil)
          .createSignedUrl(remotePath, expiresInSeconds)
          .timeout(_kSignedUrlTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeProfileObject(String? remotePath) async {
    if (remotePath == null || remotePath.isEmpty) return;
    try {
      await Supabase.instance.client.storage
          .from(bucketPerfil)
          .remove([remotePath]);
    } catch (_) {/* best-effort */}
  }

  Future<void> remove(String? remotePath) async {
    if (remotePath == null || remotePath.isEmpty) return;
    try {
      await Supabase.instance.client.storage.from(bucket).remove([remotePath]);
    } catch (_) {/* best-effort */}
  }

  String _mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
