// Formata valores e máscaras usados nos campos (moeda Brasil, CPF, telefone, etc.).
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String fmtBRL(num value) {
  final f = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return f.format(value);
}

String fmtDateShort(DateTime date) {
  return DateFormat("dd 'de' MMM", 'pt_BR').format(date);
}

String fmtRelative(DateTime date) {
  // Texto curto para listas (“agora”, “ontem”) em vez da data completa.
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return '${diff.inDays} dias';
  return DateFormat("dd 'de' MMM", 'pt_BR').format(date);
}

// Máscaras para campos de texto (CPF/CNPJ, telefone, moeda enquanto digita).
class _BaseMaskFormatter extends TextInputFormatter {
  final String Function(String digits) format;
  _BaseMaskFormatter(this.format);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpfCnpjFormatter extends _BaseMaskFormatter {
  CpfCnpjFormatter()
      : super((d) {
          d = d.length > 14 ? d.substring(0, 14) : d;
          if (d.length <= 11) {
            final b = StringBuffer();
            for (int i = 0; i < d.length; i++) {
              if (i == 3 || i == 6) b.write('.');
              if (i == 9) b.write('-');
              b.write(d[i]);
            }
            return b.toString();
          }
          final b = StringBuffer();
          for (int i = 0; i < d.length; i++) {
            if (i == 2 || i == 5) b.write('.');
            if (i == 8) b.write('/');
            if (i == 12) b.write('-');
            b.write(d[i]);
          }
          return b.toString();
        });
}

class PhoneFormatter extends _BaseMaskFormatter {
  PhoneFormatter()
      : super((d) {
          d = d.length > 11 ? d.substring(0, 11) : d;
          if (d.isEmpty) return '';
          final b = StringBuffer('(');
          for (int i = 0; i < d.length; i++) {
            if (i == 2) b.write(') ');
            if (i == 7 && d.length == 11) b.write('-');
            if (i == 6 && d.length <= 10) b.write('-');
            b.write(d[i]);
          }
          return b.toString();
        });
}

class MoneyFormatter extends TextInputFormatter {
  // Mostra reais enquanto a pessoa digita só números (valor em centavos).
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final cents = int.parse(digits);
    final formatted = fmtBRL(cents / 100);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
