import '../../../core/models/base_model.dart';

/// Representa o usuário autenticado (técnico/gestor) — espelha
/// a tabela `profiles` no Supabase.
class Usuario extends BaseModel {
  String nome;
  String email;
  String? telefone;
  String? empresa;
  String? cargo;
  double avaliacao;
  String? token;
  /// Chave no Storage (`perfil-avatars`), ex.: `<userId>/avatar_....jpg`
  String? avatarUrl;

  Usuario({
    super.localId,
    super.remoteId,
    required super.localUuid,
    required this.nome,
    required this.email,
    this.telefone,
    this.empresa,
    this.cargo,
    this.avaliacao = 0,
    this.token,
    this.avatarUrl,
    super.createdAt,
  });

  String get iniciais {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final f = parts.first.isNotEmpty ? parts.first[0] : '';
    final l = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (f + l).toUpperCase();
  }

  factory Usuario.fromJson(Map<String, dynamic> j) {
    return Usuario(
      remoteId: j['id'] as String?,
      localUuid: (j['id'] as String?) ?? '',
      nome: (j['nome'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      telefone: j['telefone'] as String?,
      empresa: j['empresa'] as String?,
      cargo: j['cargo'] as String?,
      avaliacao: ((j['avaliacao'] as num?) ?? 0).toDouble(),
      avatarUrl: j['avatar_url'] as String?,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
    );
  }

  @override
  Map<String, dynamic> toMap() => toJson();

  @override
  Map<String, dynamic> toJson() => {
        'id': remoteId,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'empresa': empresa,
        'cargo': cargo,
        'avaliacao': avaliacao,
        'avatar_url': avatarUrl,
      };
}
