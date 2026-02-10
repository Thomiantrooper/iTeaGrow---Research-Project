import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/models/user.dart';
import 'api_service.dart';

/// Admin Service for user management operations
class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  /// Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/api/users/admin/all',
        fromJson: (data) => data as List<dynamic>,
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((json) => User.fromApiResponse(json as Map<String, dynamic>))
            .toList();
      }
      debugPrint('Failed to get users: ${response.error}');
      return [];
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/users/admin/$userId/role?role=$role',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('Role updated successfully');
        return true;
      }
      debugPrint('Failed to update role: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('Error updating role: $e');
      return false;
    }
  }

  /// Update user status (activate/deactivate) (admin only)
  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/users/admin/$userId/status?is_active=$isActive',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('Status updated successfully');
        return true;
      }
      debugPrint('Failed to update status: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    }
  }

  /// Delete user (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/api/users/admin/$userId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success) {
        debugPrint('User deleted successfully');
        return true;
      }
      debugPrint('Failed to delete user: ${response.error}');
      return false;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Get all registered Bluetooth devices
  Future<Map<String, dynamic>?> getBluetoothDevices() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/bluetooth/devices',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('Error getting BLE devices: $e');
      return null;
    }
  }

  /// Get all registered WiFi devices
  Future<Map<String, dynamic>?> getWifiDevices() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/wifi/devices',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('Error getting WiFi devices: $e');
      return null;
    }
  }

  /// Get Bluetooth configuration
  Future<Map<String, dynamic>?> getBluetoothConfig() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/bluetooth/config',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('Error getting BLE config: $e');
      return null;
    }
  }

  /// Get data sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/sync/status',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('Error getting sync status: $e');
      return null;
    }
  }

  /// Trigger manual data sync
  Future<Map<String, dynamic>?> triggerSync() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/sync/trigger',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      return response.success ? response.data : null;
    } catch (e) {
      debugPrint('Error triggering sync: $e');
      return null;
    }
  }

  /// Get recent system activity
  Future<List<dynamic>?> getRecentActivity() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/disease/recent',
        fromJson: (data) => data as Map<String, dynamic>,
      );
      if (response.success && response.data != null) {
        final detections = response.data!['detections'] as List? ?? [];
        return detections.map((d) => {
          'type': 'scan',
          'action': 'Disease scan: ${d['disease_name'] ?? 'Unknown'}',
          'user': d['user_id'] ?? 'Unknown',
          'timestamp': d['created_at'] ?? 'Unknown',
        }).toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recent activity: $e');
      return null;
    }
  }
}

/// Provider for AdminService
final adminServiceProvider = Provider<AdminService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AdminService(apiService);
});

/// State notifier for managing users list
class UsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final AdminService _adminService;

  UsersNotifier(this._adminService) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _adminService.getAllUsers();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    final success = await _adminService.updateUserRole(userId, role);
    if (success) {
      await loadUsers(); // Refresh the list
    }
    return success;
  }

  Future<bool> updateUserStatus(String userId, bool isActive) async {
    final success = await _adminService.updateUserStatus(userId, isActive);
    if (success) {
      await loadUsers(); // Refresh the list
    }
    return success;
  }

  Future<bool> deleteUser(String userId) async {
    final success = await _adminService.deleteUser(userId);
    if (success) {
      await loadUsers(); // Refresh the list
    }
    return success;
  }
}

/// Provider for users list with admin operations
final usersProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return UsersNotifier(adminService);
});
