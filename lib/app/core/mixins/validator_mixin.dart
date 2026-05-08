/// Checagens repetidas nos formulários (e-mail, senha, CPF, etc.).
mixin ValidatorMixin {
  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe seu e-mail';
    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
    return null;
  }

  /// Senha: no mínimo 8 caracteres, letra e número; no máximo 72 (limite usual no login seguro).
  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Informe sua senha';
    if (v.length < 8) return 'A senha deve ter no mínimo 8 caracteres';
    if (v.length > 72) return 'A senha excede o limite de 72 caracteres';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) {
      return 'Use letras e números na sua senha';
    }
    return null;
  }

  String? validateRequired(String? v, {String label = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$label obrigatório';
    return null;
  }

  String? validateMinLength(String? v, int min, {String label = 'Campo'}) {
    if (v == null || v.trim().length < min) {
      return '$label muito curto (mín. $min caracteres)';
    }
    return null;
  }

  String? validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone incompleto';
    return null;
  }

  String? validateCpfCnpj(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) return 'CPF ou CNPJ inválido';
    return null;
  }

  String? validateMoneyPositive(String? v) {
    final n = parseMoney(v ?? '');
    if (n <= 0) return 'Informe um valor válido';
    return null;
  }

  double parseMoney(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[^\d,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
