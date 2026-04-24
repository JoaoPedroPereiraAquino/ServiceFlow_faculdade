/// Estrutura padronizada de erro vinda do backend (ver README · OpenAPI).
class ErrorModel implements Exception {
  final int codeErro;
  final String titulo;
  final String mensagem;

  const ErrorModel({
    required this.codeErro,
    required this.titulo,
    required this.mensagem,
  });

  factory ErrorModel.fromMap(Map<String, dynamic> map, {int statusCode = 0}) {
    return ErrorModel(
      codeErro: (map['codeErro'] as int?) ?? statusCode,
      titulo: (map['titulo'] as String?) ?? 'Erro inesperado',
      mensagem: (map['mensagem'] as String?) ??
          'Não foi possível concluir a operação. Tente novamente.',
    );
  }

  static const ErrorModel offline = ErrorModel(
    codeErro: -1,
    titulo: 'Sem conexão',
    mensagem: 'Operação salva localmente. Sincronizaremos quando voltar online.',
  );

  static const ErrorModel unauthorized = ErrorModel(
    codeErro: 401,
    titulo: 'Acesso negado',
    mensagem: 'Sua sessão expirou. Faça login novamente.',
  );

  @override
  String toString() => '[$codeErro] $titulo — $mensagem';
}
