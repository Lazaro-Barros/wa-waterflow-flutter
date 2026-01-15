class RegionModel {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? statusReason;
  final String? notes;
  final String? waterSourceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  RegionModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.statusReason,
    this.notes,
    this.waterSourceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      statusReason: json['status_reason'] as String?,
      notes: json['notes'] as String?,
      waterSourceId: json['water_source_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'status_reason': statusReason,
      'notes': notes,
      'water_source_id': waterSourceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      'status': status,
      'status_reason': statusReason,
      'notes': notes,
      'water_source_id': waterSourceId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (name.isNotEmpty) map['name'] = name;
    if (description != null) map['description'] = description;
    if (status.isNotEmpty) map['status'] = status;
    if (statusReason != null) map['status_reason'] = statusReason;
    if (notes != null) map['notes'] = notes;
    if (waterSourceId != null) map['water_source_id'] = waterSourceId;
    return map;
  }

  RegionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? statusReason,
    String? notes,
    String? waterSourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      notes: notes ?? this.notes,
      waterSourceId: waterSourceId ?? this.waterSourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
