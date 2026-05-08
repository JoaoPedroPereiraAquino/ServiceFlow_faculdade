// Troca de foto de perfil: arquivo local ou imagem do servidor.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';

class ProfileAvatarPicker extends StatelessWidget {
  final String iniciais;
  final String? localFilePath;
  final String? storageKey;
  final bool showRemove;
  final VoidCallback onTrocar;
  final VoidCallback? onRemover;

  const ProfileAvatarPicker({
    super.key,
    required this.iniciais,
    this.localFilePath,
    this.storageKey,
    this.showRemove = false,
    required this.onTrocar,
    this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tint,
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildImage(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onTrocar,
          icon: Icon(Icons.photo_library_outlined, size: 18),
          label: Text('Escolher foto de perfil'),
        ),
        if (showRemove && onRemover != null)
          TextButton(
            onPressed: onRemover,
            child: Text(
              'Remover foto',
              style: TextStyle(
                color: AppColors.dangerFg,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (localFilePath != null && localFilePath!.isNotEmpty) {
      return Image.file(
        File(localFilePath!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Iniciais(iniciais: iniciais),
      );
    }
    if (storageKey != null && storageKey!.isNotEmpty) {
      return _RemoteAvatar(storageKey: storageKey!, iniciais: iniciais);
    }
    return _Iniciais(iniciais: iniciais);
  }
}

class _RemoteAvatar extends StatefulWidget {
  final String storageKey;
  final String iniciais;

  const _RemoteAvatar({required this.storageKey, required this.iniciais});

  @override
  State<_RemoteAvatar> createState() => _RemoteAvatarState();
}

class _RemoteAvatarState extends State<_RemoteAvatar> {
  late final Future<String?> _future =
      GetIt.I<StorageService>().signedUrlForProfile(widget.storageKey);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (_, snap) {
        final url = snap.data;
        if (url == null) {
          return _Iniciais(iniciais: widget.iniciais);
        }
        return Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _Iniciais(iniciais: widget.iniciais),
        );
      },
    );
  }
}

class _Iniciais extends StatelessWidget {
  final String iniciais;
  const _Iniciais({required this.iniciais});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        iniciais,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
