// Camada escura e bloqueio de toques enquanto processa.
import 'package:flutter/material.dart';

class LoaderOverlay extends StatelessWidget {
  final bool show;
  final String text;
  final Widget child;

  const LoaderOverlay({
    super.key,
    required this.show,
    required this.child,
    this.text = 'Processando...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (show)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 14),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
