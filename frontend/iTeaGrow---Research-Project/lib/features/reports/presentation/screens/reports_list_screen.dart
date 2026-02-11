import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import '../../../../core/widgets/cards/tea_card.dart';
import '../../../../core/services/api_service.dart';
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
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(
          _showAllReports ? 'All Reports' : 'My Reports',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.white),
        ),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: TeaColors.white,
        elevation: 0,
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
      return Center(
        child: CircularProgressIndicator(color: TeaColors.freshLeaf),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: TeaColors.alertRust),
            const SizedBox(height: TeaSpacing.md),
            Text(_error!, style: TeaTypography.bodyMedium),
            const SizedBox(height: TeaSpacing.md),
            ElevatedButton(
              onPressed: _loadDetections,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeaColors.freshLeaf,
                foregroundColor: TeaColors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: TeaColors.mediumGray),
            const SizedBox(height: TeaSpacing.md),
            Text(
              'No scan records found',
              style: TeaTypography.titleMedium.copyWith(color: TeaColors.darkGray),
            ),
            const SizedBox(height: TeaSpacing.sm),
            Text(
              'Scan tea leaves to generate reports',
              style: TeaTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: TeaColors.freshLeaf,
      onRefresh: _loadDetections,
      child: ListView.builder(
        padding: const EdgeInsets.all(TeaSpacing.md),
        itemCount: _detections.length,
        itemBuilder: (context, index) {
          final detection = _detections[index];
          return _buildDetectionCard(detection, index);
        },
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection, int index) {
    final diseaseName = detection['disease_name'] ?? 'Unknown';
    final confidence = (detection['confidence'] ?? 0) as num;
    final severity = detection['severity'] ?? 'Unknown';
    final createdAt = detection['created_at'];
    final detectionId = detection['_id'] ?? detection['id'] ?? '';

    String formattedDate = 'N/A';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(date);
      } catch (_) {}
    }

    final severityColor = _getSeverityColor(severity);
    final isHealthy = diseaseName.toLowerCase() == 'healthy';
    final statusColor = isHealthy ? TeaColors.healthyGreen : TeaColors.alertRust;

    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
      child: TeaCard.elevated(
        onTap: () {
          if (detectionId.isNotEmpty) {
            context.push('/reports/preview/$detectionId');
          }
        },
        padding: const EdgeInsets.all(TeaSpacing.md),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                color: statusColor,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseName,
                    style: TeaTypography.titleSmall.copyWith(color: statusColor),
                  ),
                  const SizedBox(height: TeaSpacing.xs),
                  Row(
                    children: [
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}% confidence',
                        style: TeaTypography.bodySmall,
                      ),
                      const SizedBox(width: TeaSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity,
                          style: TeaTypography.labelSmall.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TeaSpacing.xs),
                  Text(
                    _showAllReports && detection['farmer_name'] != null
                        ? '$formattedDate - ${detection['farmer_name']}'
                        : formattedDate,
                    style: TeaTypography.labelSmall.copyWith(
                      color: TeaColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            // Report icon
            Column(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: TeaColors.freshLeaf.withOpacity(0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  'Report',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.freshLeaf,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: (50 * index).ms,
    ).slideY(begin: 0.1, end: 0);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return TeaColors.criticalRed;
      case 'high':
        return TeaColors.alertRust;
      case 'moderate':
        return TeaColors.warningAmber;
      case 'low':
        return TeaColors.goldenSunlight;
      case 'healthy':
      case 'none':
        return TeaColors.healthyGreen;
      default:
        return TeaColors.mediumGray;
    }
  }
}
