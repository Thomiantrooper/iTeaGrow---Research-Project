import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../providers/market_providers.dart';
import '../market_report_preview_screen.dart';

class MarketHistoryScreen extends ConsumerStatefulWidget {
  const MarketHistoryScreen({super.key});

  @override
  ConsumerState<MarketHistoryScreen> createState() => _MarketHistoryScreenState();
}

class _MarketHistoryScreenState extends ConsumerState<MarketHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(marketHistoryProvider);
    ref.invalidate(marketSummaryProvider(_selectedDays));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(
          'Market History',
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
            onPressed: _refreshData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(marketHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: TeaColors.lightGray),
                const SizedBox(height: 16),
                Text(
                  'No market history found.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              final date = DateTime.parse(item['created_at']);
              final grade = item['grade'] ?? 'Unknown';
              final price = item['price_per_kg'] ?? 0;
              final recordId = item['id'];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketReportPreviewScreen(recordId: recordId),
                      ),
                    );
                  },
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
                          child: const Icon(Icons.analytics_outlined, color: TeaColors.freshLeaf, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$grade',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: TeaColors.nearBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${price.toStringAsFixed(2)} per kg',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: TeaColors.freshLeaf,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy • HH:mm').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TeaColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: TeaColors.lightGray),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAnalyticsTab() {
    final summaryAsync = ref.watch(marketSummaryProvider(_selectedDays));

    return summaryAsync.when(
      data: (summary) {
        final totalRecords = summary['total_records'] ?? 0;
        final totalQuantity = summary['total_quantity'] ?? 0.0;
        final averagePrice = summary['average_price'] ?? 0.0;
        final gradeSummary = summary['grade_summary'] as List? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Predictions', totalRecords.toString(), Icons.assessment_outlined, TeaColors.infoSky)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Total Volume', '${totalQuantity.toInt()}kg', Icons.inventory_2_outlined, TeaColors.leafLight)),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard('Average Predicted Price', 'Rs. ${averagePrice.toStringAsFixed(2)}', Icons.payments_outlined, TeaColors.freshLeaf, fullWidth: true),

              const SizedBox(height: 24),

              if (gradeSummary.isNotEmpty) ...[
                const Text(
                  'Grade Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildGradeDistributionChart(gradeSummary),
              ],
              
              const SizedBox(height: 24),
              
              const Text(
                'Price Performance by Grade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...gradeSummary.map((g) => _buildGradePriceRow(g)).toList(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
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
              fontSize: 22,
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

  Widget _buildGradeDistributionChart(List distribution) {
    final colors = [
      TeaColors.freshLeaf,
      TeaColors.leafLight,
      TeaColors.infoSky,
      TeaColors.warningAmber,
      TeaColors.alertRust,
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
                    final data = entry.value;
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
                final data = entry.value;
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
                        data['grade'] ?? 'Unknown',
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
    );
  }

  Widget _buildGradePriceRow(Map<String, dynamic> data) {
    final grade = data['grade'];
    final avgPrice = data['avg_price'];
    final count = data['count'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeaColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grade,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '$count predictions',
                style: TextStyle(color: TeaColors.mediumGray, fontSize: 12),
              ),
            ],
          ),
          Text(
            'Rs. ${avgPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: TeaColors.freshLeaf,
            ),
          ),
        ],
      ),
    );
  }
}
