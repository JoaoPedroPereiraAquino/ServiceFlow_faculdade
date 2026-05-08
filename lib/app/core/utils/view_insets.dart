// Espaço extra em baixo (gesto do sistema ou notch) em telas com rolagem.
import 'package:flutter/material.dart';

double viewBottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom;
