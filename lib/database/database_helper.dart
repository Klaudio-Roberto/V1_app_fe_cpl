import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'meu_app_database.db');

    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Erro ao inicializar o banco de dados: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          sync_status TEXT NOT NULL,
          backend_id INTEGER
        )
      ''');
      print('Tabela "items" criada com sucesso.');
    } catch (e) {
      print('Erro ao criar a tabela "items": $e');
      rethrow;
    }
  }
  
  // Novo método para buscar itens com um determinado status de sincronização
  Future<List<Item>> getPendingItems(String status) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: 'sync_status = ?',
        whereArgs: [status],
      );
      return List.generate(maps.length, (i) {
        return Item.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar itens pendentes: $e');
      return [];
    }
  }
  
  // Novo método para buscar um item pelo ID do back-end
  Future<Item?> getItemByBackendId(int backendId) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: 'backend_id = ?',
        whereArgs: [backendId],
      );
      if (maps.isNotEmpty) {
        return Item.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar item por backend_id: $e');
      return null;
    }
  }

  Future<int> insertItem(Item item) async {
    final db = await database;
    try {
      // Define o status para 'pendente_criacao' antes de inserir
      item.syncStatus = 'pendente_criacao';
      final id = await db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (e) {
      print('Erro ao inserir item: $e');
      rethrow;
    }
  }

  Future<List<Item>> getItems() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('items');
      return List.generate(maps.length, (i) {
        return Item.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar itens: $e');
      return [];
    }
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    try {
      // Define o status para 'pendente_atualizacao' se já tiver um ID de back-end
      if (item.backendId != null) {
        item.syncStatus = 'pendente_atualizacao';
      }
      final rowsAffected = await db.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return rowsAffected;
    } catch (e) {
      print('Erro ao atualizar item: $e');
      rethrow;
    }
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    try {
      // Marca o item como 'pendente_delecao' em vez de deletar imediatamente
      final rowsAffected = await db.update(
        'items',
        {'sync_status': 'pendente_delecao'},
        where: 'id = ?',
        whereArgs: [id],
      );
      return rowsAffected;
    } catch (e) {
      print('Erro ao deletar item: $e');
      rethrow;
    }
  }
}