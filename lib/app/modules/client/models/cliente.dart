import 'package:uuid/uuid.dart';

import '../../../core/models/base_model.dart';

class Cliente extends BaseModel {
  String nome;
  String? doc;
  String? email;
  String? telefone;
  String? userId;
  String status;

  Cliente({
    super.localId,
    super.remoteId,
    String? localUuid,
    required this.nome,
    this.doc,
    this.email,
    this.telefone,
    this.userId,
    this.status = 'P',
    DateTime? createdAt,
  }) : super(
          localUuid: localUuid ?? const Uuid().v4(),
          createdAt: createdAt ?? DateTime.now(),
        );

  factory Cliente.fromMap(Map<String, dynamic> m) {
    return Cliente(
      localId: m['id'] as int?,
      remoteId: m['remote_id'] as String?,
      localUuid: m['local_uuid'] as String,
      userId: m['user_id'] as String?,
      nome: (m['nome'] as String?) ?? '',
      doc: m['doc'] as String?,
      email: m['email'] as String?,
      telefone: m['telefone'] as String?,
      status: (m['status'] as String?) ?? 'P',
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
    );
  }

  factory Cliente.fromJson(Map<String, dynamic> j) {
    return Cliente(
      remoteId: j['id'] as String?,
      localUuid: (j['local_id'] as String?) ?? const Uuid().v4(),
      userId: j['user_id'] as String?,
      nome: (j['nome'] as String?) ?? '',
      doc: j['doc'] as String?,
      email: j['email'] as String?,
      telefone: j['telefone'] as String?,
      status: 'S',
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        if (localId != null) 'id': localId,
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'user_id': userId,
        'nome': nome,
        'doc': doc,
        'email': email,
        'telefone': telefone,
        'status': status,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  @override
  Map<String, dynamic> toJson() => {
        'nome': nome,
        'doc': doc,
        'email': email,
        'telefone': telefone,
        'local_id': localUuid,
      };

  Cliente copyWith({String? nome, String? doc, String? email, String? telefone}) {
    return Cliente(
      localId: localId,
      remoteId: remoteId,
      localUuid: localUuid,
      userId: userId,
      nome: nome ?? this.nome,
      doc: doc ?? this.doc,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      status: status,
      createdAt: createdAt,
    );
  }
}
