import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tea_colors.dart';
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
              const Icon(Icons.error_outline, size: 64, color: TeaColors.alertRust),
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
                          color: TeaColors.darkGray,
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
                    color: user.isActive ? TeaColors.healthyGreen.withOpacity(0.2) : TeaColors.alertRust.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: user.isActive ? TeaColors.matureLeaf : TeaColors.criticalRed,
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
                    foregroundColor: user.isActive ? TeaColors.warningAmber : TeaColors.healthyGreen,
                  ),
                  onPressed: () => _toggleUserStatus(user),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: TeaColors.alertRust,
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
        Icon(icon, size: 14, color: color ?? TeaColors.mediumGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? TeaColors.darkGray,
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
              leading: const Icon(Icons.admin_panel_settings, color: TeaColors.alertRust),
              title: const Text('Admin'),
              subtitle: const Text('Full system access'),
              selected: user.role == UserRole.admin,
              onTap: () => _updateRole(user, 'admin'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: TeaColors.infoSky),
              title: const Text('Manager'),
              subtitle: const Text('Manage teams and data'),
              selected: user.role == UserRole.manager,
              onTap: () => _updateRole(user, 'manager'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: TeaColors.healthyGreen),
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
          backgroundColor: success ? TeaColors.healthyGreen : TeaColors.alertRust,
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
          backgroundColor: success ? TeaColors.healthyGreen : TeaColors.alertRust,
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
            style: ElevatedButton.styleFrom(backgroundColor: TeaColors.alertRust),
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
                    backgroundColor: success ? TeaColors.healthyGreen : TeaColors.alertRust,
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
        return TeaColors.alertRust;
      case UserRole.manager:
        return TeaColors.infoSky;
      case UserRole.farmer:
        return TeaColors.healthyGreen;
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

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  List<Map<String, dynamic>> _bleDevices = [];
  List<Map<String, dynamic>> _wifiDevices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(adminServiceProvider);
      // Load BLE devices
      try {
        final bleResponse = await apiService.getBluetoothDevices();
        _bleDevices =
            List<Map<String, dynamic>>.from(bleResponse?['devices'] ?? []);
      } catch (_) {
        _bleDevices = [];
      }

      // Load WiFi devices
      try {
        final wifiResponse = await apiService.getWifiDevices();
        _wifiDevices =
            List<Map<String, dynamic>>.from(wifiResponse?['devices'] ?? []);
      } catch (_) {
        _wifiDevices = [];
      }
    } catch (e) {
      _error = 'Failed to load devices: $e';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: TeaColors.alertRust),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.bluetooth,
                                        color: TeaColors.infoSky, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_bleDevices.length}',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text('BLE Devices',
                                        style: TextStyle(
                                            fontSize: 12, color: TeaColors.mediumGray)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(Icons.wifi,
                                        color: TeaColors.healthyGreen, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_wifiDevices.length}',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text('WiFi Devices',
                                        style: TextStyle(
                                            fontSize: 12, color: TeaColors.mediumGray)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // BLE Devices
                      const Text(
                        'Bluetooth Devices',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_bleDevices.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child:
                                Center(child: Text('No BLE devices registered')),
                          ),
                        )
                      else
                        ..._bleDevices.map((d) => _buildDeviceCard(
                              d,
                              Icons.bluetooth,
                              TeaColors.infoSky,
                            )),
                      const SizedBox(height: 24),
                      // WiFi Devices
                      const Text(
                        'WiFi Devices',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_wifiDevices.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: Text('No WiFi devices registered')),
                          ),
                        )
                      else
                        ..._wifiDevices.map((d) => _buildDeviceCard(
                              d,
                              Icons.wifi,
                              TeaColors.healthyGreen,
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDeviceCard(
      Map<String, dynamic> device, IconData icon, Color color) {
    final isActive = device['is_active'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(device['device_name'] ?? device['device_id'] ?? 'Unknown'),
        subtitle: Text(
          'ID: ${device['device_id'] ?? 'N/A'}\n'
          'Last seen: ${device['last_seen'] ?? 'Unknown'}',
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                (isActive ? TeaColors.healthyGreen : TeaColors.alertRust).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? TeaColors.healthyGreen : TeaColors.alertRust,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class SystemConfigScreen extends ConsumerStatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  ConsumerState<SystemConfigScreen> createState() =>
      _SystemConfigScreenState();
}

class _SystemConfigScreenState extends ConsumerState<SystemConfigScreen> {
  Map<String, dynamic>? _bluetoothConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(adminServiceProvider);
      _bluetoothConfig = await apiService.getBluetoothConfig();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IoT Sensor Thresholds',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildConfigCard(
                      'Temperature Range', '10.0 - 35.0', 'Celsius', Icons.thermostat),
                  _buildConfigCard(
                      'Humidity Range', '20.0 - 100.0', '%', Icons.water_drop),
                  _buildConfigCard('Soil Moisture Range', '0.0 - 100.0', '%',
                      Icons.grass),
                  _buildConfigCard('Light Range', '0 - 100,000', 'lux',
                      Icons.light_mode),
                  const SizedBox(height: 24),
                  const Text(
                    'Bluetooth Configuration',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_bluetoothConfig != null) ...[
                    _buildConfigCard(
                      'Service UUID',
                      _bluetoothConfig!['service_uuid'] ?? 'N/A',
                      '',
                      Icons.bluetooth,
                    ),
                    _buildConfigCard(
                      'Scan Timeout',
                      '${_bluetoothConfig!['scan_timeout'] ?? 10}',
                      'seconds',
                      Icons.timer,
                    ),
                    _buildConfigCard(
                      'Auto Reconnect',
                      _bluetoothConfig!['auto_reconnect'] == true
                          ? 'Enabled'
                          : 'Disabled',
                      '',
                      Icons.autorenew,
                    ),
                  ] else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Bluetooth config unavailable'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'ML Model Settings',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildConfigCard('Confidence Threshold', '0.25', '',
                      Icons.speed),
                  _buildConfigCard(
                      'IOU Threshold', '0.45', '', Icons.crop_square),
                  _buildConfigCard(
                      'Image Size', '640x640', 'px', Icons.image),
                  _buildConfigCard(
                      'Disease Classes',
                      'Healthy, Red Rust, Blister Blight',
                      '',
                      Icons.category),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigCard(
      String title, String value, String unit, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: TeaColors.warmAmber),
        title: Text(title),
        trailing: Text(
          unit.isNotEmpty ? '$value $unit' : value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class DataSyncScreen extends ConsumerStatefulWidget {
  const DataSyncScreen({super.key});

  @override
  ConsumerState<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends ConsumerState<DataSyncScreen> {
  Map<String, dynamic>? _syncStatus;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(adminServiceProvider);
      _syncStatus = await apiService.getSyncStatus();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    try {
      final apiService = ref.read(adminServiceProvider);
      await apiService.triggerSync();
      await _loadSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: TeaColors.healthyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: TeaColors.alertRust,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Synchronization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync status card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            _isSyncing ? Icons.sync : Icons.cloud_done,
                            size: 64,
                            color: _isSyncing ? TeaColors.warningAmber : TeaColors.healthyGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSyncing ? 'Syncing...' : 'Sync Status',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _syncStatus?['status'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              color: _syncStatus?['status'] == 'synced'
                                  ? TeaColors.healthyGreen
                                  : TeaColors.warningAmber,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_syncStatus?['last_sync'] != null)
                            Text(
                              'Last sync: ${_syncStatus!['last_sync']}',
                              style: const TextStyle(
                                  fontSize: 12, color: TeaColors.mediumGray),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.sync),
                              label: Text(
                                  _isSyncing ? 'Syncing...' : 'Sync Now'),
                              onPressed: _isSyncing ? null : _triggerSync,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sync Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSyncDetail(
                      'Pending Records',
                      '${_syncStatus?['pending_count'] ?? 0}',
                      Icons.pending_actions),
                  _buildSyncDetail(
                      'Synced Records',
                      '${_syncStatus?['synced_count'] ?? 0}',
                      Icons.check_circle),
                  _buildSyncDetail(
                      'Failed Records',
                      '${_syncStatus?['failed_count'] ?? 0}',
                      Icons.error),
                  _buildSyncDetail(
                      'Database',
                      _syncStatus?['database_status'] ?? 'Connected',
                      Icons.storage),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncDetail(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: TeaColors.leafLight),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

class SystemLogsScreen extends ConsumerStatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  ConsumerState<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends ConsumerState<SystemLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(adminServiceProvider);
      final response = await apiService.getRecentActivity();
      _logs = List<Map<String, dynamic>>.from(response ?? []);
    } catch (_) {
      _logs = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: TeaColors.mediumGray),
                      SizedBox(height: 16),
                      Text('No activity logs available',
                          style: TextStyle(color: TeaColors.mediumGray)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadLogs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogCard(log);
                    },
                  ),
                ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final type = log['type'] ?? 'info';
    final iconData = _getLogIcon(type);
    final color = _getLogColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(iconData, color: color, size: 20),
        ),
        title: Text(
          log['action'] ?? log['message'] ?? 'Unknown activity',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${log['user'] ?? 'System'} - ${log['timestamp'] ?? 'Unknown time'}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'scan':
        return Icons.document_scanner;
      case 'auth':
        return Icons.login;
      case 'device':
        return Icons.devices;
      case 'sync':
        return Icons.sync;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'scan':
        return TeaColors.infoSky;
      case 'auth':
        return TeaColors.clayPot;
      case 'device':
        return TeaColors.leafLight;
      case 'sync':
        return TeaColors.healthyGreen;
      case 'error':
        return TeaColors.alertRust;
      default:
        return TeaColors.mediumGray;
    }
  }
}
