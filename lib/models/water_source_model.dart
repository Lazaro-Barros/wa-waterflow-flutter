class WaterSourceModel {
  final String id;
  final String name;
  final String? address;
  final String locationDescription;
  final double? latitude;
  final double? longitude;
  final String status;
  final String? statusReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaterSourceModel({
    required this.id,
    required this.name,
    this.address,
    required this.locationDescription,
    this.latitude,
    this.longitude,
    required this.status,
    this.statusReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaterSourceModel.fromJson(Map<String, dynamic> json) {
    return WaterSourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      locationDescription: json['location_description'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'] as String,
      statusReason: json['status_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location_description': locationDescription,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'status_reason': statusReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'address': address,
      'location_description': locationDescription,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'status_reason': statusReason,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (name.isNotEmpty) map['name'] = name;
    if (address != null) map['address'] = address;
    if (locationDescription.isNotEmpty) map['location_description'] = locationDescription;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (status.isNotEmpty) map['status'] = status;
    if (statusReason != null) map['status_reason'] = statusReason;
    return map;
  }

  bool validateCoordinates() {
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      return false;
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      return false;
    }
    return true;
  }

  WaterSourceModel copyWith({
    String? id,
    String? name,
    String? address,
    String? locationDescription,
    double? latitude,
    double? longitude,
    String? status,
    String? statusReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterSourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      locationDescription: locationDescription ?? this.locationDescription,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
