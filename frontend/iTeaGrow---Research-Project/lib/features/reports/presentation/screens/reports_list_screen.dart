import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/providers/auth_provider.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  List<Map<String, dynamic>> _detections = [];
  bool _isLoading = true;
  String? _error;
  bool _showAllReports = false;

  bool get _isAdminOrManager {
    final authState = ref.read(authStateProvider);
    final role = authState.user?.role.name ?? 'farmer';
    return role == 'admin' || role == 'manager';
  }

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final endpoint = (_isAdminOrManager && _showAllReports)
          ? '/api/reports/admin/all'
          : '/api/reports/user/history';
      final response = await apiService.get<Map<String, dynamic>>(
        endpoint,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        _detections =
            List<Map<String, dynamic>>.from(response.data!['detections'] ?? []);
      } else {
        _detections = [];
      }
    } catch (e) {
      _error = 'Failed to load detections: $e';
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
        title: Text(_showAllReports ? 'All Reports' : 'My Reports'),
        actions: [
          if (_isAdminOrManager)
            IconButton(
              icon: Icon(_showAllReports ? Icons.person : Icons.people),
              tooltip: _showAllReports ? 'My Reports' : 'All Reports',
              onPressed: () {
                setState(() => _showAllReports = !_showAllReports);
                _loadDetections();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetections,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_detections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No scan records found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Scan tea leaves to generate reports',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDetections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _detections.length,
        itemBuilder: (context, index) {
          final detection = _detections[index];
          return _buildDetectionCard(detection);
        },
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final diseaseName = detection['disease_name'] ?? 'Unknown';
    final confidence = (detection['confidence'] ?? 0) as num;
    final severity = detection['severity'] ?? 'Unknown';
    final createdAt = detection['created_at'];
    final detectionId =
        detection['_id'] ?? detection['id'] ?? '';

    String formattedDate = 'N/A';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(date);
      } catch (_) {}
    }

    final severityColor = _getSeverityColor(severity);
    final isHealthy =
        diseaseName.toLowerCase() == 'healthy';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (detectionId.isNotEmpty) {
            context.push('/reports/preview/$detectionId');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isHealthy ? Colors.green : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(confidence * 100).toStringAsFixed(1)}% confidence',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              fontSize: 10,
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showAllReports && detection['farmer_name'] != null
                          ? '$formattedDate - ${detection['farmer_name']}'
                          : formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Generate report button
              Column(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.primaryGreen.withOpacity(0.8),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade800;
      case 'healthy':
      case 'none':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
