// Dados da OS: status, valor, fotos (aqui e no servidor) e assinatura em Base64.
import 'package:uuid/uuid.dart';

import '../../../core/models/base_model.dart';

enum OsStatus { aberto, execucao, executada }

/// Texto para gravar no banco e para mostrar na tela.
extension OsStatusX on OsStatus {
  String get raw {
    switch (this) {
      case OsStatus.aberto:
        return 'aberto';
      case OsStatus.execucao:
        return 'execucao';
      case OsStatus.executada:
        return 'executada';
    }
  }

  String get label {
    switch (this) {
      case OsStatus.aberto:
        return 'Em aberto';
      case OsStatus.execucao:
        return 'Em execução';
      case OsStatus.executada:
        return 'Executada';
    }
  }

  static OsStatus parse(String? raw) {
    switch (raw) {
      case 'execucao':
        return OsStatus.execucao;
      case 'executada':
        return OsStatus.executada;
      case 'aberto':
      default:
        return OsStatus.aberto;
    }
  }
}

class OrdemServico extends BaseModel {
  String codigo;
  String? clienteLocalUuid;
  String? clienteRemoteId;
  String? clienteNome;
  String descricao;
  double valor;
  OsStatus osStatus;
  /// Foto salva no aparelho (câmera).
  String? fotoAntesPath;
  String? fotoDepoisPath;

  /// Chave da foto no armazenamento (para abrir na tela).
  String? fotoAntesRemotePath;
  String? fotoDepoisRemotePath;

  String? assinaturaBase64;
  String tecnico;
  String? userId;

  /// P = ainda não enviada ao servidor; S = já enviada.
  String status;

  OrdemServico({
    super.localId,
    super.remoteId,
    String? localUuid,
    required this.codigo,
    required this.descricao,
    required this.valor,
    this.clienteLocalUuid,
    this.clienteRemoteId,
    this.clienteNome,
    this.osStatus = OsStatus.aberto,
    this.fotoAntesPath,
    this.fotoDepoisPath,
    this.fotoAntesRemotePath,
    this.fotoDepoisRemotePath,
    this.assinaturaBase64,
    this.tecnico = '—',
    this.userId,
    this.status = 'P',
    DateTime? createdAt,
  }) : super(
          localUuid: localUuid ?? const Uuid().v4(),
          createdAt: createdAt ?? DateTime.now(),
        );

  factory OrdemServico.fromMap(Map<String, dynamic> m) {
    return OrdemServico(
      localId: m['id'] as int?,
      remoteId: m['remote_id'] as String?,
      localUuid: m['local_uuid'] as String,
      userId: m['user_id'] as String?,
      codigo: (m['codigo'] as String?) ?? '',
      clienteLocalUuid: m['cliente_local_uuid'] as String?,
      clienteRemoteId: m['cliente_remote_id'] as String?,
      clienteNome: m['cliente_nome'] as String?,
      descricao: (m['descricao'] as String?) ?? '',
      valor: ((m['valor'] as num?) ?? 0).toDouble(),
      osStatus: OsStatusX.parse(m['os_status'] as String?),
      fotoAntesPath: m['foto_antes_path'] as String?,
      fotoDepoisPath: m['foto_depois_path'] as String?,
      fotoAntesRemotePath: m['foto_antes_remote_path'] as String?,
      fotoDepoisRemotePath: m['foto_depois_remote_path'] as String?,
      assinaturaBase64: m['assinatura_base64'] as String?,
      tecnico: (m['tecnico'] as String?) ?? '—',
      status: (m['status'] as String?) ?? 'P',
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
    );
  }

  factory OrdemServico.fromJson(Map<String, dynamic> j) {
    return OrdemServico(
      remoteId: j['id'] as String?,
      localUuid: (j['local_id'] as String?) ?? const Uuid().v4(),
      userId: j['user_id'] as String?,
      codigo: (j['codigo'] as String?) ?? '',
      clienteRemoteId: j['cliente_id'] as String?,
      clienteNome: j['cliente_nome'] as String?,
      descricao: (j['descricao'] as String?) ?? '',
      valor: ((j['valor'] as num?) ?? 0).toDouble(),
      osStatus: OsStatusX.parse(j['status'] as String?),
      // Na resposta da API esses campos vêm como caminho remoto; aqui viram os campos *_remote.
      fotoAntesPath: null,
      fotoDepoisPath: null,
      fotoAntesRemotePath: (j['foto_antes_remote_path'] as String?) ??
          j['foto_antes_path'] as String?,
      fotoDepoisRemotePath: (j['foto_depois_remote_path'] as String?) ??
          j['foto_depois_path'] as String?,
      assinaturaBase64: j['assinatura_base64'] as String?,
      tecnico: (j['tecnico'] as String?) ?? '—',
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
        'codigo': codigo,
        'cliente_local_uuid': clienteLocalUuid,
        'cliente_remote_id': clienteRemoteId,
        'cliente_nome': clienteNome,
        'descricao': descricao,
        'valor': valor,
        'os_status': osStatus.raw,
        'foto_antes_path': fotoAntesPath,
        'foto_depois_path': fotoDepoisPath,
        'foto_antes_remote_path': fotoAntesRemotePath,
        'foto_depois_remote_path': fotoDepoisRemotePath,
        'assinatura_base64': assinaturaBase64,
        'tecnico': tecnico,
        'status': status,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  @override
  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'cliente_id': clienteRemoteId,
        'cliente_nome': clienteNome,
        'descricao': descricao,
        'valor': valor,
        'status': osStatus.raw,
        'foto_antes_path': fotoAntesRemotePath,
        'foto_depois_path': fotoDepoisRemotePath,
        'foto_antes_remote_path': fotoAntesRemotePath,
        'foto_depois_remote_path': fotoDepoisRemotePath,
        'assinatura_base64': assinaturaBase64,
        'tecnico': tecnico,
        'local_id': localUuid,
      };

  static const _placeholderTecnico = '—';

  /// Nome no rodapé: técnico; se não houver, usa o cliente.
  String get nomeResponsavelRodape {
    if (tecnico.isNotEmpty && tecnico != _placeholderTecnico) {
      return tecnico;
    }
    final n = clienteNome?.trim();
    if (n != null && n.isNotEmpty) return n;
    return _placeholderTecnico;
  }
}

/// Contagem e somas para o painel inicial.
class OsSummary {
  final int total, aberto, execucao, executada;
  final double totalValue, abertoValue, execucaoValue, executadaValue;

  const OsSummary({
    this.total = 0,
    this.aberto = 0,
    this.execucao = 0,
    this.executada = 0,
    this.totalValue = 0,
    this.abertoValue = 0,
    this.execucaoValue = 0,
    this.executadaValue = 0,
  });

  factory OsSummary.fromList(List<OrdemServico> list) {
    double sum(Iterable<OrdemServico> l) => l.fold(0.0, (a, b) => a + b.valor);
    final ab = list.where((o) => o.osStatus == OsStatus.aberto);
    final ex = list.where((o) => o.osStatus == OsStatus.execucao);
    final fe = list.where((o) => o.osStatus == OsStatus.executada);

    return OsSummary(
      total: list.length,
      aberto: ab.length,
      execucao: ex.length,
      executada: fe.length,
      totalValue: sum(list),
      abertoValue: sum(ab),
      execucaoValue: sum(ex),
      executadaValue: sum(fe),
    );
  }
}
