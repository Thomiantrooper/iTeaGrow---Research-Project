import 'package:flutter/material.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import '../../../../core/widgets/cards/tea_card.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/datasources/disease_storage_service.dart';
import '../../domain/entities/disease_detection_result.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen>
    with SingleTickerProviderStateMixin {
  final DiseaseStorageService _storageService = DiseaseStorageService();
  late TabController _tabController;

  List<DiseaseDetectionResult> _detections = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authToken = ref.read(authStateProvider).accessToken;

    if (authToken == null || authToken.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.scan_history_login_required;
        _isLoading = false;
      });
      return;
    }

    try {
      final futures = await Future.wait([
        _storageService.getDetections(limit: 50, authToken: authToken),
        _storageService.getDetailedStatistics(days: 30, authToken: authToken),
      ]);

      setState(() {
        _detections = futures[0] as List<DiseaseDetectionResult>;
        _statistics = futures[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.scan_history_load_failed(e.toString());
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
          AppLocalizations.of(context)!.disease_scan_history,
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: TeaColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TeaColors.white,
          indicatorWeight: 3,
          labelColor: TeaColors.white,
          unselectedLabelColor: TeaColors.white.withOpacity(0.7),
          tabs: [
            Tab(icon: Icon(Icons.history), text: AppLocalizations.of(context)!.scan_history_tab),
            Tab(icon: Icon(Icons.bar_chart), text: AppLocalizations.of(context)!.analytics_title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: TeaColors.mediumGray),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: TeaColors.darkGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.common_retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.freshLeaf,
              foregroundColor: TeaColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: TeaColors.lightGray),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.scan_history_empty,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: TeaColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.scan_history_empty_subtitle,
              style: TextStyle(color: TeaColors.darkGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _detections.length,
        itemBuilder: (context, index) {
          return _buildHistoryItem(_detections[index], index);
        },
      ),
    );
  }

  Widget _buildHistoryItem(DiseaseDetectionResult detection, int index) {
    final isHealthy = detection.diseaseType == 'Healthy';
    final statusColor = isHealthy ? TeaColors.healthyGreen : TeaColors.alertRust;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailDialog(detection),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.diseaseType,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.scan_history_confidence_pct(
                              (detection.confidence * 100).toStringAsFixed(1),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: TeaColors.darkGray,
                            ),
                          ),
                          if (detection.severity.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(detection.severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                detection.severity,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getSeverityColor(detection.severity),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(detection.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: TeaColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Environmental indicators
                if (detection.temperature != null)
                  Column(
                    children: [
                      Icon(Icons.thermostat, size: 16, color: TeaColors.warningAmber),
                      Text(
                        '${detection.temperature!.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 11,
                          color: TeaColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: TeaColors.healthyGreen, size: 20),
                  tooltip: 'Generate Report',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (detection.dbId != null) {
                      context.push('/reports/preview/${detection.dbId}');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_statistics == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.disease_no_analytics),
      );
    }

    final totalScans = _statistics!['total_scans'] ?? 0;
    final healthyCount = _statistics!['healthy_count'] ?? 0;
    final infectedCount = _statistics!['infected_count'] ?? 0;
    final healthRate = _statistics!['health_rate'] ?? 0.0;
    final diseaseDistribution = _statistics!['disease_distribution'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Scans', totalScans.toString(), Icons.search, TeaColors.infoSky)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Healthy', healthyCount.toString(), Icons.check_circle, TeaColors.healthyGreen)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Infected', infectedCount.toString(), Icons.warning, TeaColors.alertRust)),
            ],
          ),

          const SizedBox(height: 20),

          // Health rate
          _buildHealthRateCard(healthRate.toDouble()),

          const SizedBox(height: 20),

          // Disease distribution pie chart
          if (diseaseDistribution.isNotEmpty)
            _buildDiseaseDistributionChart(diseaseDistribution),

          const SizedBox(height: 20),

          // Severity distribution
          if (_statistics!['severity_distribution'] != null)
            _buildSeverityDistribution(_statistics!['severity_distribution'] as Map<String, dynamic>),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TeaColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRateCard(double healthRate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TeaColors.freshLeaf.withOpacity(0.1),
            TeaColors.freshLeaf.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeaColors.freshLeaf.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.scan_history_overall_health,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${healthRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: healthRate >= 70 ? TeaColors.healthyGreen : TeaColors.alertRust,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: healthRate / 100,
              minHeight: 12,
              backgroundColor: TeaColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                healthRate >= 70 ? TeaColors.healthyGreen : TeaColors.alertRust,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseDistributionChart(List distribution) {
    final colors = [
      TeaColors.healthyGreen,
      TeaColors.alertRust,
      TeaColors.warningAmber,
      TeaColors.infoSky,
      TeaColors.leafLight,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disease Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: distribution.asMap().entries.map((entry) {
                        final data = entry.value as Map<String, dynamic>;
                        final index = entry.key;
                        return PieChartSectionData(
                          value: (data['count'] as int).toDouble(),
                          color: colors[index % colors.length],
                          title: '${data['count']}',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: TeaColors.white,
                          ),
                          radius: 50,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: distribution.asMap().entries.map((entry) {
                    final data = entry.value as Map<String, dynamic>;
                    final index = entry.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data['disease_name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDistribution(Map<String, dynamic> severityData) {
    final low = severityData['Low'] ?? 0;
    final medium = severityData['Medium'] ?? 0;
    final high = severityData['High'] ?? 0;
    final total = low + medium + high;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TeaColors.shadowVale,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.scan_history_severity_levels,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSeverityBar('Low', low, total, TeaColors.healthyGreen),
          const SizedBox(height: 12),
          _buildSeverityBar('Medium', medium, total, TeaColors.warningAmber),
          const SizedBox(height: 12),
          _buildSeverityBar('High', high, total, TeaColors.alertRust),
        ],
      ),
    );
  }

  Widget _buildSeverityBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor: TeaColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  void _showDetailDialog(DiseaseDetectionResult detection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: TeaColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TeaColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildDetailHeader(detection),
                      const SizedBox(height: 20),
                      _buildDetailSection(AppLocalizations.of(context)!.scan_history_detection_details, [
                        _buildDetailRow(AppLocalizations.of(context)!.disease_type, detection.diseaseType),
                        _buildDetailRow(AppLocalizations.of(context)!.common_confidence, '${(detection.confidence * 100).toStringAsFixed(1)}%'),
                        _buildDetailRow(AppLocalizations.of(context)!.disease_severity, detection.severity),
                        _buildDetailRow(AppLocalizations.of(context)!.scan_history_detected_at, _formatDateTime(detection.timestamp)),
                      ]),
                      if (detection.temperature != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection(AppLocalizations.of(context)!.scan_history_env_conditions, [
                          if (detection.temperature != null)
                            _buildDetailRow('Temperature', '${detection.temperature!.toStringAsFixed(1)}°C'),
                          if (detection.humidity != null)
                            _buildDetailRow('Humidity', '${detection.humidity!.toStringAsFixed(1)}%'),
                          if (detection.airQuality != null)
                            _buildDetailRow('Air Quality', 'AQI ${detection.airQuality!.toStringAsFixed(0)}'),
                        ]),
                      ],
                      if (detection.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('Recommendations', [
                          ...detection.recommendations.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: TeaColors.freshLeaf),
                                const SizedBox(width: 8),
                                Expanded(child: Text(r)),
                              ],
                            ),
                          ),),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailHeader(DiseaseDetectionResult detection) {
    final isHealthy = detection.diseaseType == 'Healthy';
    final statusColor = isHealthy ? TeaColors.healthyGreen : TeaColors.alertRust;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
            color: statusColor,
            size: 36,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detection.diseaseType,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                isHealthy ? AppLocalizations.of(context)!.scan_history_healthy_leaf : AppLocalizations.of(context)!.disease_detected,
                style: TextStyle(color: TeaColors.darkGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TeaColors.leafPale,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: TeaColors.darkGray),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return TeaColors.healthyGreen;
      case 'Medium':
        return TeaColors.warningAmber;
      case 'High':
        return TeaColors.alertRust;
      default:
        return TeaColors.mediumGray;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
