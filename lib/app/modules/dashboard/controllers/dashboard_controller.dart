import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../auth/models/usuario.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../client/models/cliente.dart';
import '../../client/repositories/cliente_repository.dart';
import '../../service_order/models/ordem_servico.dart';
import '../../service_order/repositories/ordem_servico_repository.dart';

/// Controller do Dashboard. `extends ChangeNotifier` (regra do README).
class DashboardController extends ChangeNotifier {
  final _osRepo = GetIt.I<OrdemServicoRepository>();
  final _cliRepo = GetIt.I<ClienteRepository>();
  final _authRepo = GetIt.I<AuthRepository>();

  bool loading = true;
  Usuario? usuario;
  List<OrdemServico> osList = [];
  List<Cliente> clientes = [];
  OsSummary summary = const OsSummary();

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      usuario = await _authRepo.currentUser();
      osList = await _osRepo.listarTodas();
      clientes = await _cliRepo.listarTodos();
      summary = OsSummary.fromList(osList);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
