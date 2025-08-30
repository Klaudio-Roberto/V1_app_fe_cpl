import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';

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

  // 1. Crie os FocusNodes
  late FocusNode _nameFocusNode;
  late FocusNode _descriptionFocusNode;

  @override
  void initState() {
    super.initState();
    _loadItems();
    // Inicialize os FocusNodes no initState
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // 2. Descarte os FocusNodes no dispose para evitar vazamentos de memória
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _nameController.dispose(); // Também descarte os TextEditingControllers
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _dbHelper.getItems();
      if (!mounted) return;
      setState(() {
        _items = items;
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
        _showSnackBar('Item adicionado com sucesso!');
      } else {
        newItem.id = _selectedItem!.id;
        await _dbHelper.updateItem(newItem);
        _showSnackBar('Item atualizado com sucesso!');
        _selectedItem = null;
      }

      // Limpa os campos do formulário
      _nameController.clear();
      _descriptionController.clear();

      // 3. Mova o foco após a operação
      _nameFocusNode.requestFocus(); // Solicita o foco para o campo "Nome do Item"

      _loadItems(); // Recarrega a lista
    } catch (e) {
      _showSnackBar('Erro ao salvar item: ${e.toString()}');
      print('Erro ao salvar item na UI: $e');
    }
  }

  Future<void> _deleteItem(int id) async {
    try {
      await _dbHelper.deleteItem(id);
      _showSnackBar('Item deletado com sucesso!');
      _loadItems();
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
    // Ao editar, move o foco para o campo de nome para facilitar a edição
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
        title: const Text('(v1_fe_cpl/app_4b)App de Itens'),
        backgroundColor: const Color.from(alpha: 1, red: 0.318, green: 0.851, blue: 0.208),   // Eu incluir essa linha por conta e risco.
      ),

      body: Padding(                              // "Margens"
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode, // 4. Associe o FocusNode
              decoration: const InputDecoration(
                labelText: 'Nome do Item',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next, // Tecla "Next" no teclado
              onSubmitted: (_) {
                _descriptionFocusNode.requestFocus(); // Move para o próximo campo ao pressionar "Next"
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode, // 4. Associe o FocusNode
              decoration: const InputDecoration(
                labelText: 'Descrição do Item',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done, // Tecla "Done" no teclado
              onSubmitted: (_) {
                _addItem(); // Submete o formulário ao pressionar "Done"
              },
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

