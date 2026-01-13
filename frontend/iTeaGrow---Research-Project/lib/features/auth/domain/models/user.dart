import '../../../../core/enums/app_enums.dart';

class User {
  final int id;
  final String username;
  final String fullName;
  final UserRole role;
  final String languagePreference;
  final String? email;
  final String? phone;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.languagePreference,
    this.email,
    this.phone,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      fullName: map['full_name'] as String? ?? '',
      role: _parseRole(map['role'] as String),
      languagePreference: map['language_preference'] as String? ?? 'en',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role.name,
      'language_preference': languagePreference,
      'email': email,
      'phone': phone,
    };
  }

  static UserRole _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'farmer':
        return UserRole.farmer;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.farmer;
    }
  }

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    UserRole? role,
    String? languagePreference,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      languagePreference: languagePreference ?? this.languagePreference,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
