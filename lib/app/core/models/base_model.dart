/// Base comum aos dados salvos: código local, código no servidor, identificador no aparelho e datas.

abstract class BaseModel {
  /// Número interno no banco local. Pode ficar vazio até a primeira gravação.
  int? localId;

  /// Código que o servidor usa nos dados na nuvem. Fica vazio até sincronizar.
  String? remoteId;

  /// Código fixo gerado no aparelho para reconhecer o mesmo registro antes e depois de enviar ao servidor.
  String localUuid;

  DateTime? createdAt;

  BaseModel({
    this.localId,
    this.remoteId,
    required this.localUuid,
    this.createdAt,
  });

  /// Formato para gravar no banco local.
  Map<String, dynamic> toMap();

  /// Formato para enviar ao servidor (JSON).
  Map<String, dynamic> toJson();
}
