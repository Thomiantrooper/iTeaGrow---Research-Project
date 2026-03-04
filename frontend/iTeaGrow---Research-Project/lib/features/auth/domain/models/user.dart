import '../../../../core/enums/app_enums.dart';

class User {
  final String id; // Changed to String for MongoDB ObjectId support
  final String username;
  final String fullName;
  final UserRole role;
  final String languagePreference;
  final String? email;
  final String? phone;
  final DateTime? createdAt;
  final bool isActive;
  final String access;       // 'mobile' | 'web' | 'both'
  final String? googleEmail; // Gmail registered for Google Sign-In

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.languagePreference,
    this.email,
    this.phone,
    this.createdAt,
    this.isActive = true,
    this.access = 'both',
    this.googleEmail,
  });

  /// Create user from local database map (int id)
  factory User.fromMap(Map<String, dynamic> map) {
    // Handle both int and String IDs
    final dynamic rawId = map['id'] ?? map['_id'];
    final String id = rawId is int ? rawId.toString() : rawId as String;

    return User(
      id: id,
      username: map['username'] as String,
      fullName: map['full_name'] as String? ?? '',
      role: _parseRole(map['role'] as String? ?? 'farmer'),
      languagePreference: map['language_preference'] as String? ?? 'en',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isActive: map['is_active'] as bool? ?? true,
      access: map['access'] as String? ?? 'both',
      googleEmail: map['google_email'] as String?,
    );
  }

  /// Create user from API response
  factory User.fromApiResponse(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: _parseRole(json['role'] as String? ?? 'farmer'),
      languagePreference: json['language_preference'] as String? ?? 'en',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isActive: json['is_active'] as bool? ?? true,
      access: json['access'] as String? ?? 'both',
      googleEmail: json['google_email'] as String?,
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
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive,
      'access': access,
      'google_email': googleEmail,
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
    String? id,
    String? username,
    String? fullName,
    UserRole? role,
    String? languagePreference,
    String? email,
    String? phone,
    DateTime? createdAt,
    bool? isActive,
    String? access,
    String? googleEmail,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      languagePreference: languagePreference ?? this.languagePreference,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      access: access ?? this.access,
      googleEmail: googleEmail ?? this.googleEmail,
    );
  }
}
