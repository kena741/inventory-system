class UserModel {
  final String id;
  final String? email;
  final String phone;
  final String role;
  final String? authUserId;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.email,
    required this.phone,
    required this.role,
    this.authUserId,
    this.firstName,
    this.lastName,
    required this.createdAt,
  });

  String get fullName => [
        if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
        if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
      ].join(' ').trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fn = (json['first_name'] as String?)?.trim();
    final ln = (json['last_name'] as String?)?.trim();
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: (json['phone_number'] as String?) ??
          (json['phone'] as String?) ??
          '',
      role: (json['role'] as String?) ?? 'seller',
      authUserId:
          (json['user_id'] as String?) ?? (json['auth_user_id'] as String?),
      firstName: fn,
      lastName: ln,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phone,
      'role': role,
      'user_id': authUserId,
      'first_name': firstName,
      'last_name': lastName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

