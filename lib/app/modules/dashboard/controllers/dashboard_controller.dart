// Dados do início: usuário, OS e clientes (notifica a tela).
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../auth/models/usuario.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../client/models/cliente.dart';
import '../../client/repositories/cliente_repository.dart';
import '../../service_order/models/ordem_servico.dart';
import '../../service_order/repositories/ordem_servico_repository.dart';

class DashboardController extends ChangeNotifier {
  final _osRepo = GetIt.I<OrdemServicoRepository>();
  final _cliRepo = GetIt.I<ClienteRepository>();
  final _authRepo = GetIt.I<AuthRepository>();

  /// Carregando dados do banco local: barra fina em cima sem trocar a tela inteira.
  bool inFlight = true;

  Usuario? usuario;
  List<OrdemServico> osList = [];
  List<Cliente> clientes = [];
  OsSummary summary = const OsSummary();

  Future<void> load() async {
    inFlight = true;
    notifyListeners();
    try {
      usuario = await _authRepo.currentUser();
      osList = await _osRepo.listarTodas();
      clientes = await _cliRepo.listarTodos();
      summary = OsSummary.fromList(osList);
    } finally {
      inFlight = false;
      notifyListeners();
    }
  }
}
