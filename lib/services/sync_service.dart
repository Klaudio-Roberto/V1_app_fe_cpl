import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/item.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _apiUrl = 'http://10.0.2.2:8000/api/items/'; // Use 10.0.2.2 para o emulador Android

  Future<void> syncData() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print('Sem conexão. Sincronização cancelada.');
      return;
    }

    print('Conexão detectada. Iniciando sincronização...');

    try {
      // 1. Enviar dados pendentes para o back-end
      await _sendPendingData();

      // 2. Receber dados atualizados do back-end
      await _fetchLatestData();

      print('Sincronização concluída com sucesso!');
    } catch (e) {
      print('Erro na sincronização: $e');
    }
  }

  Future<void> _sendPendingData() async {
    // Sincronização de criações pendentes
    final itemsToCreate = await _dbHelper.getPendingItems('pendente_criacao');
    for (var item in itemsToCreate) {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item.toMap()),
      );
      if (response.statusCode == 201) {
        final backendItem = jsonDecode(response.body);
        item.backendId = backendItem['id'];
        item.syncStatus = 'sincronizado';
        await _dbHelper.updateItem(item);
      }
    }
    
    // Sincronização de atualizações pendentes
    final itemsToUpdate = await _dbHelper.getPendingItems('pendente_atualizacao');
    for (var item in itemsToUpdate) {
      final response = await http.put(
        Uri.parse('$_apiUrl${item.backendId}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item.toMap()),
      );
      if (response.statusCode == 200) {
        item.syncStatus = 'sincronizado';
        await _dbHelper.updateItem(item);
      }
    }

    // Sincronização de deleções pendentes
    final itemsToDelete = await _dbHelper.getPendingItems('pendente_delecao');
    for (var item in itemsToDelete) {
      final response = await http.delete(Uri.parse('$_apiUrl${item.backendId}/'));
      if (response.statusCode == 204) {
        // Se a deleção no servidor for bem-sucedida, remove o item localmente
        await _dbHelper.deleteItem(item.id!);
      }
    }
  }

  Future<void> _fetchLatestData() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> backendItems = jsonDecode(response.body);
      for (var backendItem in backendItems) {
        final localItem = await _dbHelper.getItemByBackendId(backendItem['id']);
        if (localItem == null) {
          // Item existe no servidor, mas não localmente. Insere-o.
          final newItem = Item.fromMap(backendItem);
          newItem.syncStatus = 'sincronizado';
          await _dbHelper.insertItem(newItem);
        } else {
          // TODO: Implementar lógica de resolução de conflitos (por exemplo, usando timestamp)
          // Se a data de atualização do servidor for mais recente, atualize o item localmente.
        }
      }
    }
  }
}