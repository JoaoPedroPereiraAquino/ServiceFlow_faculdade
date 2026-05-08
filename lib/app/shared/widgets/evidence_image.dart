// Mostra foto da OS: arquivo local ou imagem pelo caminho no servidor.
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

class EvidenceImage extends StatefulWidget {
  final String? localPath;
  final String? remotePath;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const EvidenceImage({
    super.key,
    this.localPath,
    this.remotePath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  State<EvidenceImage> createState() => _EvidenceImageState();
}

class _EvidenceImageState extends State<EvidenceImage> {
  Future<String?>? _signedUrlFuture;
  String? _lastRemotePath;

  @override
  Widget build(BuildContext context) {
    final localOk =
        widget.localPath != null && File(widget.localPath!).existsSync();

    if (localOk) {
      return Image.file(
        File(widget.localPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _buildRemote(),
      );
    }

    return _buildRemote();
  }

  Widget _buildRemote() {
    final path = widget.remotePath;
    if (path == null || path.isEmpty) {
      return widget.errorWidget ?? _emptyBox();
    }

    if (_lastRemotePath != path) {
      _lastRemotePath = path;
      _signedUrlFuture = StorageService.instance.signedUrlFor(path);
    }

    return FutureBuilder<String?>(
      future: _signedUrlFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              ColoredBox(
                color: AppColors.surfaceAlt,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        }
        final url = snap.data;
        if (url == null) {
          return widget.errorWidget ?? _emptyBox();
        }
        return Image.network(
          url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, __, ___) => widget.errorWidget ?? _emptyBox(),
        );
      },
    );
  }

  Widget _emptyBox() => Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined,
            size: 18, color: AppColors.textFaint),
      );
}
