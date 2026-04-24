// Testes básicos de smoke do app ServiceFlow.
// Como o app inicializa Supabase + SQLite, mantemos o teste focado em
// componentes puros que não dependem de I/O.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serviceflow/app/shared/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton renderiza o label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            label: 'Entrar',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Entrar'), findsOneWidget);
  });
}
