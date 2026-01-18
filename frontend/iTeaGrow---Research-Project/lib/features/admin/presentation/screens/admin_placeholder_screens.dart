import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../auth/domain/models/user.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh users when screen loads
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usersProvider.notifier).loadUsers();
            },
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(usersProvider.notifier).loadUsers();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No users found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final roleColor = _getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Text(
                    _getInitials(user.fullName),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: user.isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (user.email != null && user.email!.isNotEmpty)
                  _buildInfoChip(Icons.email, user.email!),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _buildInfoChip(Icons.phone, user.phone!),
                _buildInfoChip(
                  Icons.badge,
                  _getRoleDisplayName(user.role),
                  color: roleColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Change Role'),
                  onPressed: () => _showRoleDialog(user),
                ),
                TextButton.icon(
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 18,
                  ),
                  label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: user.isActive ? Colors.orange : Colors.green,
                  ),
                  onPressed: () => _toggleUserStatus(user),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => _confirmDelete(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _showRoleDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select new role for ${user.fullName}:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Admin'),
              subtitle: const Text('Full system access'),
              selected: user.role == UserRole.admin,
              onTap: () => _updateRole(user, 'admin'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.blue),
              title: const Text('Manager'),
              subtitle: const Text('Manage teams and data'),
              selected: user.role == UserRole.manager,
              onTap: () => _updateRole(user, 'manager'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Farmer'),
              subtitle: const Text('Basic access'),
              selected: user.role == UserRole.farmer,
              onTap: () => _updateRole(user, 'farmer'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRole(User user, String newRole) async {
    Navigator.pop(context);

    final success = await ref.read(usersProvider.notifier).updateUserRole(
      user.id,
      newRole,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Role updated successfully'
                : 'Failed to update role',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    final newStatus = !user.isActive;

    final success = await ref.read(usersProvider.notifier).updateUserStatus(
      user.id,
      newStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User ${newStatus ? 'activated' : 'deactivated'}'
                : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(usersProvider.notifier).deleteUser(user.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'User deleted successfully'
                          : 'Failed to delete user',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.farmer:
        return Colors.green;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.farmer:
        return 'Farmer';
    }
  }
}

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Management')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.devices, size: 100, color: Colors.purple),
              const SizedBox(height: 24),
              const Text(
                'Device Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin only - Configure IoT devices',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SystemConfigScreen extends StatelessWidget {
  const SystemConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Configuration')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings, size: 100, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'System Configuration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin only - System settings and thresholds',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataSyncScreen extends StatelessWidget {
  const DataSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Synchronization')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync, size: 100, color: Colors.teal),
              const SizedBox(height: 24),
              const Text(
                'Data Synchronization',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin only - Sync data to cloud',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SystemLogsScreen extends StatelessWidget {
  const SystemLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'System Logs',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin only - View system activity logs',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
