/// Contrato base para toda entidade de negócio do ServiceFlow.
///
/// Toda nova entidade DEVE herdar desta classe (regra do README).
abstract class BaseModel {
  /// Identificador local (SQLite). Pode ser nulo até a primeira persistência.
  int? localId;

  /// Identificador remoto (UUID Supabase). Nulo enquanto pendente de sincronização.
  String? remoteId;

  /// Identificador estável usado durante a fase offline (UUID gerado no cliente).
  String localUuid;

  DateTime? createdAt;

  BaseModel({
    this.localId,
    this.remoteId,
    required this.localUuid,
    this.createdAt,
  });

  /// Conversão para persistência local (SQLite).
  Map<String, dynamic> toMap();

  /// Conversão para o backend (JSON enviado ao Supabase).
  Map<String, dynamic> toJson();
}
