class TruckModel {
  final String id;
  final String plate;
  final int capacityLiters;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  TruckModel({
    required this.id,
    required this.plate,
    required this.capacityLiters,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    return TruckModel(
      id: json['id'] as String,
      plate: json['plate'] as String,
      capacityLiters: json['capacity_liters'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'capacity_liters': capacityLiters,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'plate': plate,
      'capacity_liters': capacityLiters,
      'description': description,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (plate.isNotEmpty) map['plate'] = plate;
    if (capacityLiters > 0) map['capacity_liters'] = capacityLiters;
    if (description != null) map['description'] = description;
    return map;
  }

  bool validatePlate() {
    // Formato antigo: ABC-1234 (3 letras, hífen, 4 números)
    final oldFormat = RegExp(r'^[A-Z]{3}-[0-9]{4}$');
    // Formato novo: ABC1D23 (3 letras, 1 número, 1 letra, 2 números)
    final newFormat = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    final normalizedPlate = plate.toUpperCase().trim();
    return oldFormat.hasMatch(normalizedPlate) || newFormat.hasMatch(normalizedPlate);
  }

  TruckModel copyWith({
    String? id,
    String? plate,
    int? capacityLiters,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TruckModel(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
