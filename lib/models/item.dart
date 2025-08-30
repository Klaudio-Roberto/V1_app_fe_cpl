class Item {
  int? id;
  String name;
  String description;

  Item({this.id, required this.name, required this.description});

  // Converte um objeto Item em um Map para ser inserido no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  // Cria um objeto Item a partir de um Map (lido do banco de dados).
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, description: $description}';
  }
}