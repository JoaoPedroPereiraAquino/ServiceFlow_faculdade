import 'package:flutter/material.dart';

/// Espaço extra inferior (gesto de navegação / home indicator) para
/// conteúdo rolável que não fica abaixo do bottom bar do [Scaffold].
double viewBottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom;
