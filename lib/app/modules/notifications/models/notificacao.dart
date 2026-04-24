import 'package:uuid/uuid.dart';

import '../../../core/models/base_model.dart';

class Notificacao extends BaseModel {
  String kind;
  String icon;
  String titulo;
  String? corpo;
  bool lida;
  String? userId;

  Notificacao({
    super.localId,
    super.remoteId,
    String? localUuid,
    this.kind = 'info',
    this.icon = 'bell',
    required this.titulo,
    this.corpo,
    this.lida = false,
    this.userId,
    DateTime? createdAt,
  }) : super(
          localUuid: localUuid ?? const Uuid().v4(),
          createdAt: createdAt ?? DateTime.now(),
        );

  factory Notificacao.fromMap(Map<String, dynamic> m) {
    return Notificacao(
      localId: m['id'] as int?,
      remoteId: m['remote_id'] as String?,
      localUuid: m['local_uuid'] as String,
      userId: m['user_id'] as String?,
      kind: (m['kind'] as String?) ?? 'info',
      icon: (m['icon'] as String?) ?? 'bell',
      titulo: (m['titulo'] as String?) ?? '',
      corpo: m['corpo'] as String?,
      lida: (m['lida'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
    );
  }

  factory Notificacao.fromJson(Map<String, dynamic> j) {
    final remote = j['id'] as String?;
    return Notificacao(
      remoteId: remote,
      // Usa o `remote_id` como `local_uuid` para a notificação ser
      // determinística entre pulls — assim o `getByLocalUuid` sempre
      // encontra o registro local existente e não duplica.
      localUuid: remote ?? const Uuid().v4(),
      userId: j['user_id'] as String?,
      kind: (j['kind'] as String?) ?? 'info',
      icon: (j['icon'] as String?) ?? 'bell',
      titulo: (j['titulo'] as String?) ?? '',
      corpo: j['corpo'] as String?,
      lida: (j['lida'] as bool?) ?? false,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        if (localId != null) 'id': localId,
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'user_id': userId,
        'kind': kind,
        'icon': icon,
        'titulo': titulo,
        'corpo': corpo,
        'lida': lida ? 1 : 0,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  @override
  Map<String, dynamic> toJson() => {
        'kind': kind,
        'icon': icon,
        'titulo': titulo,
        'corpo': corpo,
        'lida': lida,
      };
}
