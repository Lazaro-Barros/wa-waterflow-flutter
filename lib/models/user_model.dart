class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int tenantId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      tenantId: json['tenant_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'tenant_id': tenantId,
    };
  }
}

