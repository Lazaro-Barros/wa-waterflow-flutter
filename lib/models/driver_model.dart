import 'truck_model.dart';

class DriverModel {
  final String id;
  final String truckId;
  final TruckModel? truck; // Para exibir informações do caminhão
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.truckId,
    this.truck,
    required this.name,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      truckId: json['truck_id'] as String,
      truck: json['truck'] != null
          ? TruckModel.fromJson(json['truck'] as Map<String, dynamic>)
          : null,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'truck_id': truckId,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'truck_id': truckId,
      'name': name,
      'phone': phone,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (truckId.isNotEmpty) map['truck_id'] = truckId;
    if (name.isNotEmpty) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    return map;
  }

  DriverModel copyWith({
    String? id,
    String? truckId,
    TruckModel? truck,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truck: truck ?? this.truck,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
