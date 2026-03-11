import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';

class YieldHistoryScreen extends StatefulWidget {
  const YieldHistoryScreen({super.key});

  @override
  State<YieldHistoryScreen> createState() => _YieldHistoryScreenState();
}

class _YieldHistoryScreenState extends State<YieldHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _records = [];
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');
      final headers = {'Accept': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http
          .get(Uri.parse('${ApiConfig.dbYield}?limit=100'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _records = (data as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load records (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _analytics {
    final total = _records.length;
    double totalYield = 0;
    double totalAvgDaily = 0;
    final Map<String, int> divisionMap = {};

    for (final r in _records) {
      totalYield +=
          ((r['total_predicted_yield_kg'] ?? 0.0) as num).toDouble();
      totalAvgDaily +=
          ((r['average_daily_yield_kg'] ?? 0.0) as num).toDouble();
      final div = (r['division_id'] ?? 'Unknown') as String;
      divisionMap[div] = (divisionMap[div] ?? 0) + 1;
    }

    return {
      'total': total,
      'total_yield': totalYield,
      'avg_daily': total > 0 ? totalAvgDaily / total : 0.0,
      'division_distribution': divisionMap.entries
          .map((e) => {'division': e.key, 'count': e.value})
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(
          'Yield History',
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
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
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
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildHistoryTab(), _buildAnalyticsTab()],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: TeaColors.mediumGray),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: TeaColors.darkGray)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: TeaColors.lightGray),
            const SizedBox(height: 16),
            Text(
              'No yield predictions yet.',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: TeaColors.darkGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRecordCard(_records[index]),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> item) {
    final division = item['division_id'] ?? 'N/A';
    final totalYield =
        ((item['total_predicted_yield_kg'] ?? 0.0) as num).toDouble();
    final avgDaily =
        ((item['average_daily_yield_kg'] ?? 0.0) as num).toDouble();
    final days = item['prediction_days'] ?? 1;
    final createdAt = item['created_at'];
    DateTime? date;
    try {
      date = createdAt != null ? DateTime.parse(createdAt.toString()) : null;
    } catch (_) {}

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TeaColors.freshLeaf.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.trending_up,
                  color: TeaColors.freshLeaf, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Division $division — $days day${days == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${totalYield.toStringAsFixed(1)} kg  •  Avg/day: ${avgDaily.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: TeaColors.freshLeaf),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(date),
                      style:
                          TextStyle(fontSize: 12, color: TeaColors.mediumGray),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final a = _analytics;
    final total = a['total'] as int;
    final totalYield = a['total_yield'] as double;
    final avgDaily = a['avg_daily'] as double;
    final divDist = a['division_distribution'] as List;

    final colors = [
      TeaColors.freshLeaf,
      TeaColors.infoSky,
      TeaColors.warningAmber,
      TeaColors.alertRust,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Predictions', total.toString(),
                      Icons.assessment, TeaColors.infoSky)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                      'Total Yield',
                      '${totalYield.toStringAsFixed(0)} kg',
                      Icons.inventory_2_outlined,
                      TeaColors.freshLeaf)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Avg. Daily Yield',
            '${avgDaily.toStringAsFixed(1)} kg/day',
            Icons.show_chart,
            TeaColors.leafLight,
            fullWidth: true,
          ),
          if (divDist.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Division Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TeaColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: TeaColors.shadowVale,
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: divDist.asMap().entries.map((entry) {
                            final data =
                                entry.value as Map<String, dynamic>;
                            final color = colors[entry.key % colors.length];
                            return PieChartSectionData(
                              value: (data['count'] as int).toDouble(),
                              color: color,
                              title: '${data['count']}',
                              titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
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
                      children: divDist.asMap().entries.map((entry) {
                        final data =
                            entry.value as Map<String, dynamic>;
                        final color = colors[entry.key % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Text(data['division'] ?? 'Unknown',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
