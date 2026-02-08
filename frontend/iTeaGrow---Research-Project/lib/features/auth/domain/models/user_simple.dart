import '../../../../core/enums/app_enums.dart';

class UserSimple {
  final int id;
  final String username;
  final String fullName;
  final UserRole role;

  UserSimple({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });
}
