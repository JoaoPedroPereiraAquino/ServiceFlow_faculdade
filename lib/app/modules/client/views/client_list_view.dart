// Lista de clientes: toque para editar; excluir só se não tiver OS ligada.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/mixins/ui_feedback_mixin.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bar_custom.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';
import 'client_form_view.dart';

class ClientListView extends StatefulWidget {
  const ClientListView({super.key});

  @override
  State<ClientListView> createState() => _ClientListViewState();
}

class _ClientListViewState extends State<ClientListView> with UiFeedbackMixin {
  final _repo = GetIt.I<ClienteRepository>();
  final _sync = GetIt.I<OfflineSyncService>();
  List<Cliente> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listarTodos();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _editar(Cliente c) async {
    final u = await Navigator.of(context).push<Cliente>(
      MaterialPageRoute(
        builder: (_) => ClientFormView(cliente: c),
      ),
    );
    if (u != null && mounted) await _load();
  }

  Future<void> _excluir(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text(
          'Remover o cadastro de "${c.nome}" não pode ser desfeito na nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir', style: TextStyle(color: AppColors.dangerFg)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.excluir(c);
      if (!mounted) return;
      showFeedback('Cliente removido', kind: FeedbackKind.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showFeedback(e.toString().replaceFirst('Exception: ', ''),
          kind: FeedbackKind.error);
    }
  }

  Future<void> _novo() async {
    final c = await Navigator.of(context).push<Cliente>(
      MaterialPageRoute(
        builder: (_) => const ClientFormView(),
      ),
    );
    if (c != null && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppBarCustom(
        title: 'Clientes',
        subtitle: 'Toque para editar · menu para excluir',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novo,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sync.syncAll();
          await _load();
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Nenhum cliente ainda',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          onTap: () => _editar(c),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.borderSoft),
                          ),
                          title: Text(
                            c.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: c.doc != null && c.doc!.isNotEmpty
                              ? Text(
                                  c.doc!,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                )
                              : (c.email != null && c.email!.isNotEmpty
                                  ? Text(
                                      c.email!,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null),
                          trailing: PopupMenuButton<String>(
                            onSelected: (a) {
                              if (a == 'del') _excluir(c);
                              if (a == 'edit') _editar(c);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined, size: 20),
                                  title: Text('Editar'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'del',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.dangerFg,
                                  ),
                                  title: Text(
                                    'Excluir',
                                    style: TextStyle(color: AppColors.dangerFg),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
