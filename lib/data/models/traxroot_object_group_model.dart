class TraxrootObjectGroupModel {
  final String? id;
  final String? name;
  final String? objects;

  const TraxrootObjectGroupModel({
    this.id,
    this.name,
    this.objects,
  });

  factory TraxrootObjectGroupModel.fromMap(Map<String, dynamic> map) {
    return TraxrootObjectGroupModel(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      objects: map['objects']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'objects': objects,
    };
  }

  int get groupId => int.tryParse(id ?? '') ?? 0;

  List<int> get objectIds {
    if (objects == null || objects!.isEmpty) return [];
    return objects!
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .toList();
  }
}
