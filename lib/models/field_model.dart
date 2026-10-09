class FieldModel {
  final String id;
  final String name;
  final int displayOrder;

  const FieldModel({
    required this.id,
    required this.name,
    this.displayOrder = 0,
  });

  FieldModel copyWith({
    String? id,
    String? name,
    int? displayOrder,
  }) {
    return FieldModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_order': displayOrder,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map) {
    return FieldModel(
      id: map['id'] as String,
      name: map['name'] as String,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          displayOrder == other.displayOrder;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ displayOrder.hashCode;
}
