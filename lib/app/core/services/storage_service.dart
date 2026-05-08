// Envia fotos de ordens e de perfil; gera links temporários para mostrar imagens privadas na nuvem.
// Cada usuário fica com sua pasta no armazenamento, conforme as regras no servidor.
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String bucket = 'os-evidencias';
  static const String bucketPerfil = 'perfil-avatars';
  final _uuid = const Uuid();

  /// Envia o arquivo para a nuvem e devolve o caminho lá (não é link aberto).
  /// Devolve nulo se não houver usuário logado ou se o arquivo não existir.
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

  /// Gera um link temporário (válido alguns minutos ou horas) para usar em Image.network.
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

  /// Envia foto de perfil; caminho na nuvem: pasta do usuário + nome do arquivo.
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

  /// Link temporário para imagem no espaço de fotos de perfil.
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
