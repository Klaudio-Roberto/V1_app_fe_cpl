import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import '../services/sync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Item> _items = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Item? _selectedItem;

  late FocusNode _nameFocusNode;
  late FocusNode _descriptionFocusNode;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    SyncService().syncData(); // Inicia a sincronização ao carregar a tela
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _dbHelper.getItems();
      if (!mounted) return;
      setState(() {
        // Filtra os itens com status de deleção pendente para não exibi-los
        _items = items.where((item) => item.syncStatus != 'pendente_delecao').toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao carregar itens: ${e.toString()}');
      print('Erro ao carregar itens na UI: $e');
    }
  }

  Future<void> _addItem() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showSnackBar('Por favor, preencha todos os campos.');
      return;
    }

    final newItem = Item(
      name: _nameController.text,
      description: _descriptionController.text,
    );

    try {
      if (_selectedItem == null) {
        await _dbHelper.insertItem(newItem);
        _showSnackBar('Item adicionado localmente!');
      } else {
        newItem.id = _selectedItem!.id;
        newItem.backendId = _selectedItem!.backendId; // Garante que o ID do back-end é mantido
        await _dbHelper.updateItem(newItem);
        _showSnackBar('Item atualizado localmente!');
        _selectedItem = null;
      }

      _nameController.clear();
      _descriptionController.clear();
      _nameFocusNode.requestFocus();
      _loadItems();
      SyncService().syncData(); // Inicia uma sincronização após a operação
    } catch (e) {
      _showSnackBar('Erro ao salvar item: ${e.toString()}');
      print('Erro ao salvar item na UI: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      // Em vez de deletar, apenas marca o item para deleção
      await _dbHelper.deleteItem(id);
      _showSnackBar('Item marcado para ser deletado!');
      _loadItems();
      SyncService().syncData(); // Inicia uma sincronização para enviar a deleção
    } catch (e) {
      _showSnackBar('Erro ao deletar item: ${e.toString()}');
      print('Erro ao deletar item na UI: $e');
    }
  }

  void _editItem(Item item) {
    setState(() {
      _selectedItem = item;
      _nameController.text = item.name;
      _descriptionController.text = item.description;
    });
    _nameFocusNode.requestFocus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('(v2_app_fe) App de Itens'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: const InputDecoration(
                labelText: 'Nome do Item',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _descriptionFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Descrição do Item',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addItem(),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: Icon(_selectedItem == null ? Icons.add : Icons.save),
              label: Text(_selectedItem == null ? 'Adicionar Item' : 'Atualizar Item'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const Divider(height: 30, thickness: 1),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Nenhum item adicionado ainda.\nAdicione um item acima!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item.description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editItem(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    if (item.id != null) {
                                      _deleteItem(item.id!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}