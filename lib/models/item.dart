class Item {
  int? id;
  String name;
  String description;
  String syncStatus;
  int? backendId;

  Item({
    this.id,
    required this.name,
    required this.description,
    this.syncStatus = 'sincronizado',
    this.backendId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sync_status': syncStatus,
      'backend_id': backendId,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      syncStatus: map['sync_status'],
      backendId: map['backend_id'],
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, description: $description, syncStatus: $syncStatus, backendId: $backendId}';
  }
}