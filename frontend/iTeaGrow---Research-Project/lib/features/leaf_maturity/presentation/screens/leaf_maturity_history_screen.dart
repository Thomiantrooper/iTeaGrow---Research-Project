import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';

class LeafMaturityHistoryScreen extends StatefulWidget {
  const LeafMaturityHistoryScreen({super.key});

  @override
  State<LeafMaturityHistoryScreen> createState() =>
      _LeafMaturityHistoryScreenState();
}

class _LeafMaturityHistoryScreenState extends State<LeafMaturityHistoryScreen>
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
          .get(Uri.parse('${ApiConfig.dbMaturity}?limit=100'), headers: headers)
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

  // ── Analytics ──────────────────────────────────────────────────────────────

  Map<String, dynamic> get _analytics {
    final total = _records.length;
    int tenderCount = 0;
    int matureCount = 0;
    final Map<String, int> speciesMap = {};

    for (final r in _records) {
      final maturity = (r['maturity'] ?? '').toString().toLowerCase();
      if (maturity == 'tender') tenderCount++;
      if (maturity == 'mature') matureCount++;
      final species = (r['species'] ?? 'Unknown') as String;
      speciesMap[species] = (speciesMap[species] ?? 0) + 1;
    }
    final avgConfidence = total > 0
        ? _records
                .map((r) => (r['maturity_confidence'] ?? 0.0) as num)
                .fold(0.0, (a, b) => a + b) /
            total
        : 0.0;

    return {
      'total': total,
      'tender': tenderCount,
      'mature': matureCount,
      'avg_confidence': avgConfidence,
      'species_distribution': speciesMap.entries
          .map((e) => {'species': e.key, 'count': e.value})
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(
          'Maturity History',
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
              'No maturity scans yet.',
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
    final maturity = item['maturity'] ?? 'Unknown';
    final species = item['species'] ?? 'Unknown';
    final confidence = ((item['maturity_confidence'] ?? 0.0) as num).toDouble();
    final createdAt = item['created_at'];
    DateTime? date;
    try {
      date = createdAt != null ? DateTime.parse(createdAt.toString()) : null;
    } catch (_) {}

    final isTender = maturity.toString().toLowerCase() == 'tender';
    final statusColor =
        isTender ? TeaColors.healthyGreen : TeaColors.warmAmber;

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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.eco, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$species — $maturity',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColor),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(date),
                      style: TextStyle(
                          fontSize: 12, color: TeaColors.mediumGray),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                maturity,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor),
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
    final tender = a['tender'] as int;
    final mature = a['mature'] as int;
    final avgConf = a['avg_confidence'] as double;
    final speciesDist = a['species_distribution'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total Scans', total.toString(),
                      Icons.search, TeaColors.infoSky)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Tender', tender.toString(),
                      Icons.eco, TeaColors.healthyGreen)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Mature', mature.toString(),
                      Icons.grass, TeaColors.warmAmber)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Avg. Maturity Confidence',
            '${(avgConf * 100).toStringAsFixed(1)}%',
            Icons.verified,
            TeaColors.freshLeaf,
            fullWidth: true,
          ),
          if (speciesDist.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Species Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPieChart(
              speciesDist,
              labelKey: 'species',
              colors: [TeaColors.infoSky, TeaColors.freshLeaf],
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
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPieChart(List distribution,
      {required String labelKey, required List<Color> colors}) {
    return Container(
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
                  sections: distribution.asMap().entries.map((entry) {
                    final data = entry.value as Map<String, dynamic>;
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
              children: distribution.asMap().entries.map((entry) {
                final data = entry.value as Map<String, dynamic>;
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
                      Text(data[labelKey] ?? 'Unknown',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
