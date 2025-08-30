import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Construtor privado para o singleton.
  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Getter para o banco de dados, garantindo que ele seja inicializado uma única vez.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados.
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'meu_app_database.db');

      return await openDatabase(
        path,
        version: 1, // Versão do banco de dados
        onCreate: _onCreate, // Chamado na primeira vez que o DB é criado
        onUpgrade: _onUpgrade, // Chamado quando a versão do DB é atualizada
      );
    } catch (e) {
      // Loga o erro e relança para que a camada superior possa lidar.
      print('Erro ao inicializar o banco de dados: $e');
      rethrow;
    }
  }

  // Método para criar tabelas no banco de dados.
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL
        )
      ''');
      print('Tabela "items" criada com sucesso.');
    } catch (e) {
      print('Erro ao criar a tabela "items": $e');
      rethrow;
    }
  }

  // Método para lidar com atualizações de esquema do banco de dados (migrações).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Exemplo de como adicionar uma nova coluna em uma versão futura.
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE items ADD COLUMN status TEXT DEFAULT "ativo"');
        print('Tabela "items" atualizada para a versão 2: adicionado "status".');
      } catch (e) {
        print('Erro na migração da versão 1 para 2: $e');
        rethrow;
      }
    }
    // Adicione mais blocos 'if' para futuras versões e migrações.
  }

  // --- Operações CRUD (Create, Read, Update, Delete) ---

  // Insere um novo item no banco de dados.
  Future<int> insertItem(Item item) async {
    final db = await database; // Garante que o DB está aberto
    try {
      final id = await db.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, // Substitui se houver conflito de ID.
      );
      print('Item inserido com ID: $id');
      return id;
    } catch (e) {
      print('Erro ao inserir item: $e');
      rethrow; // Relança para a UI tratar.
    }
  }

  // Busca todos os itens do banco de dados.
  Future<List<Item>> getItems() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('items');
      print('Itens recuperados: ${maps.length}');
      // Converte a lista de Maps em uma lista de objetos Item.
      return List.generate(maps.length, (i) {
        return Item.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar itens: $e');
      return []; // Retorna uma lista vazia em caso de erro.
    }
  }

  // Atualiza um item existente no banco de dados.
  Future<int> updateItem(Item item) async {
    final db = await database;
    try {
      final rowsAffected = await db.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      print('Itens atualizados: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Erro ao atualizar item: $e');
      rethrow;
    }
  }

  // Deleta um item do banco de dados.
  Future<int> deleteItem(int id) async {
    final db = await database;
    try {
      final rowsAffected = await db.delete(
        'items',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Itens deletados: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Erro ao deletar item: $e');
      rethrow;
    }
  }
}