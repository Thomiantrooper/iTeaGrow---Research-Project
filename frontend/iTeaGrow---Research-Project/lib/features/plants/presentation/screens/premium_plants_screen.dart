import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Premium Plants/Growth Monitoring Screen
class PremiumPlantsScreen extends ConsumerStatefulWidget {
  const PremiumPlantsScreen({super.key});

  @override
  ConsumerState<PremiumPlantsScreen> createState() => _PremiumPlantsScreenState();
}

class _PremiumPlantsScreenState extends ConsumerState<PremiumPlantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBlock = 'All Blocks';

  final List<String> _blocks = ['All Blocks', 'Block A', 'Block B', 'Block C', 'Block D'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Plant Monitoring',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: TeaColors.nearBlack),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TeaColors.freshLeaf,
          labelColor: TeaColors.freshLeaf,
          unselectedLabelColor: TeaColors.darkGray,
          tabs: const [
            Tab(text: 'Growth Stages'),
            Tab(text: 'Health Status'),
            Tab(text: 'Maturity'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Block Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TeaSpacing.md,
              vertical: TeaSpacing.sm,
            ),
            color: TeaColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _blocks.map((block) {
                  final isSelected = block == _selectedBlock;
                  return Padding(
                    padding: const EdgeInsets.only(right: TeaSpacing.sm),
                    child: FilterChip(
                      label: Text(block),
                      selected: isSelected,
                      selectedColor: TeaColors.leafPale,
                      checkmarkColor: TeaColors.freshLeaf,
                      onSelected: (selected) {
                        setState(() => _selectedBlock = block);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrowthStagesTab(),
                _buildHealthStatusTab(),
                _buildMaturityTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/disease-detection'),
        backgroundColor: TeaColors.freshLeaf,
        icon: const Icon(Icons.camera_alt, color: TeaColors.white),
        label: const Text('Scan Leaf', style: TextStyle(color: TeaColors.white)),
      ),
    );
  }

  Widget _buildGrowthStagesTab() {
    return SingleChildScrollView(
      padding: TeaSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Plants',
                  value: '12,450',
                  icon: Icons.eco,
                  color: TeaColors.freshLeaf,
                ),
              ),
              const SizedBox(width: TeaSpacing.smd),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Ready to Harvest',
                  value: '2,340',
                  icon: Icons.check_circle_outline,
                  color: TeaColors.healthyGreen,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: TeaSpacing.lg),

          const TeaSectionHeader(
            title: 'Growth Stages Overview',
            icon: Icons.timeline,
          ),
          const SizedBox(height: TeaSpacing.sm),

          // Growth Stage Progress
          _buildGrowthStageCard(
            stage: 'Bud Stage',
            description: 'Young buds, 1-2 leaves unfolded',
            count: 3200,
            percentage: 25.7,
            color: TeaColors.leafLight,
            icon: Icons.filter_vintage,
          ).animate().fadeIn(delay: 100.ms),

          _buildGrowthStageCard(
            stage: 'P+1 (First Leaf)',
            description: 'One leaf below bud fully open',
            count: 2850,
            percentage: 22.9,
            color: TeaColors.leafMedium,
            icon: Icons.eco,
          ).animate().fadeIn(delay: 200.ms),

          _buildGrowthStageCard(
            stage: 'P+2 (Two Leaves)',
            description: 'Two leaves below bud - Optimal harvest',
            count: 2340,
            percentage: 18.8,
            color: TeaColors.freshLeaf,
            icon: Icons.spa,
            isHighlighted: true,
          ).animate().fadeIn(delay: 300.ms),

          _buildGrowthStageCard(
            stage: 'P+3 (Three Leaves)',
            description: 'Three leaves below bud',
            count: 2180,
            percentage: 17.5,
            color: TeaColors.matureLeaf,
            icon: Icons.grass,
          ).animate().fadeIn(delay: 400.ms),

          _buildGrowthStageCard(
            stage: 'Mature',
            description: 'Fully mature, past optimal harvest',
            count: 1880,
            percentage: 15.1,
            color: TeaColors.deepForest,
            icon: Icons.nature,
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: TeaSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHealthStatusTab() {
    return SingleChildScrollView(
      padding: TeaSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Overview Card
          TeaCard.elevated(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TeaSpacing.md),
                      decoration: BoxDecoration(
                        color: TeaColors.healthyGreen.withOpacity(0.1),
                        borderRadius: TeaRadius.radiusMd,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: TeaColors.healthyGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: TeaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Health Score',
                            style: TeaTypography.bodyMedium.copyWith(
                              color: TeaColors.darkGray,
                            ),
                          ),
                          Text(
                            '87%',
                            style: TeaTypography.displayMedium.copyWith(
                              color: TeaColors.healthyGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TeaStatusBadge.healthy(label: 'Good'),
                  ],
                ),
                const SizedBox(height: TeaSpacing.md),
                const TeaProgressBar(
                  value: 0.87,
                  color: TeaColors.healthyGreen,
                  showPercentage: false,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: TeaSpacing.lg),

          const TeaSectionHeader(
            title: 'Health Distribution',
            icon: Icons.pie_chart_outline,
          ),
          const SizedBox(height: TeaSpacing.sm),

          _buildHealthStatusCard(
            status: 'Healthy',
            count: 10240,
            percentage: 82.3,
            color: TeaColors.healthyGreen,
            icon: Icons.check_circle,
          ),

          _buildHealthStatusCard(
            status: 'Minor Issues',
            count: 1450,
            percentage: 11.6,
            color: TeaColors.warningAmber,
            icon: Icons.warning,
          ),

          _buildHealthStatusCard(
            status: 'Needs Attention',
            count: 620,
            percentage: 5.0,
            color: TeaColors.alertRust,
            icon: Icons.error,
          ),

          _buildHealthStatusCard(
            status: 'Critical',
            count: 140,
            percentage: 1.1,
            color: TeaColors.criticalRed,
            icon: Icons.dangerous,
          ),

          const SizedBox(height: TeaSpacing.lg),

          TeaSectionHeader(
            title: 'Common Issues Detected',
            icon: Icons.bug_report_outlined,
            actionLabel: 'View All',
            onAction: () => context.push('/disease-detection'),
          ),
          const SizedBox(height: TeaSpacing.sm),

          _buildIssueCard(
            disease: 'Blister Blight',
            affectedCount: 340,
            severity: 'Medium',
            severityColor: TeaColors.warningAmber,
          ),

          _buildIssueCard(
            disease: 'Red Spider Mite',
            affectedCount: 180,
            severity: 'Low',
            severityColor: TeaColors.infoSky,
          ),

          _buildIssueCard(
            disease: 'Tea Mosquito Bug',
            affectedCount: 100,
            severity: 'High',
            severityColor: TeaColors.alertRust,
          ),

          const SizedBox(height: TeaSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMaturityTab() {
    return SingleChildScrollView(
      padding: TeaSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maturity Summary
          TeaCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harvest Readiness',
                  style: TeaTypography.titleMedium,
                ),
                const SizedBox(height: TeaSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildMaturityIndicator(
                        label: 'Ready Now',
                        value: '2,340',
                        color: TeaColors.healthyGreen,
                      ),
                    ),
                    Expanded(
                      child: _buildMaturityIndicator(
                        label: 'In 3 Days',
                        value: '1,850',
                        color: TeaColors.goldenSunlight,
                      ),
                    ),
                    Expanded(
                      child: _buildMaturityIndicator(
                        label: 'In 1 Week',
                        value: '3,420',
                        color: TeaColors.infoSky,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: TeaSpacing.lg),

          const TeaSectionHeader(
            title: 'Block-wise Maturity',
            icon: Icons.grid_view,
          ),
          const SizedBox(height: TeaSpacing.sm),

          _buildBlockMaturityCard(
            block: 'Block A',
            readyPercentage: 45,
            totalPlants: 3200,
            estimatedYield: '156 kg',
          ),

          _buildBlockMaturityCard(
            block: 'Block B',
            readyPercentage: 32,
            totalPlants: 2850,
            estimatedYield: '134 kg',
          ),

          _buildBlockMaturityCard(
            block: 'Block C',
            readyPercentage: 68,
            totalPlants: 3100,
            estimatedYield: '189 kg',
          ),

          _buildBlockMaturityCard(
            block: 'Block D',
            readyPercentage: 22,
            totalPlants: 3300,
            estimatedYield: '98 kg',
          ),

          const SizedBox(height: TeaSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TeaCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: TeaSpacing.sm),
          Text(
            value,
            style: TeaTypography.headlineMedium.copyWith(
              color: TeaColors.nearBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TeaTypography.bodySmall.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthStageCard({
    required String stage,
    required String description,
    required int count,
    required double percentage,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
      child: TeaCard(
        variant: isHighlighted ? TeaCardVariant.elevated : TeaCardVariant.outlined,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: TeaRadius.radiusSm,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: TeaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(stage, style: TeaTypography.titleSmall),
                      if (isHighlighted) ...[
                        const SizedBox(width: TeaSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TeaSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TeaColors.healthyGreen,
                            borderRadius: TeaRadius.radiusXs,
                          ),
                          child: Text(
                            'HARVEST',
                            style: TeaTypography.labelSmall.copyWith(
                              color: TeaColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count.toString(),
                  style: TeaTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusCard({
    required String status,
    required int count,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
      child: TeaCard.outlined(
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: TeaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: TeaTypography.titleSmall),
                  const SizedBox(height: TeaSpacing.xs),
                  TeaProgressBar(
                    value: percentage / 100,
                    color: color,
                    height: 6,
                    showPercentage: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: TeaSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count.toString(),
                  style: TeaTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard({
    required String disease,
    required int affectedCount,
    required String severity,
    required Color severityColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
      child: TeaCard.outlined(
        onTap: () => context.push('/disease-detection'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.sm),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: TeaRadius.radiusSm,
              ),
              child: Icon(Icons.bug_report, color: severityColor, size: 20),
            ),
            const SizedBox(width: TeaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disease, style: TeaTypography.titleSmall),
                  Text(
                    '$affectedCount plants affected',
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TeaSpacing.sm,
                vertical: TeaSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: TeaRadius.radiusSm,
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
      ),
    );
  }

  Widget _buildMaturityIndicator({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TeaTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TeaTypography.labelSmall.copyWith(
            color: TeaColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBlockMaturityCard({
    required String block,
    required int readyPercentage,
    required int totalPlants,
    required String estimatedYield,
  }) {
    final color = readyPercentage > 50
        ? TeaColors.healthyGreen
        : readyPercentage > 30
            ? TeaColors.goldenSunlight
            : TeaColors.infoSky;

    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.smd),
      child: TeaCard.elevated(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(block, style: TeaTypography.titleMedium),
                TeaStatusBadge(
                  label: '$readyPercentage% ready',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.sm),
            TeaProgressBar(
              value: readyPercentage / 100,
              color: color,
              height: 8,
              showPercentage: false,
            ),
            const SizedBox(height: TeaSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalPlants plants',
                  style: TeaTypography.bodySmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
                Text(
                  'Est. yield: $estimatedYield',
                  style: TeaTypography.bodySmall.copyWith(
                    color: TeaColors.freshLeaf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: TeaRadius.topXxl,
        ),
        padding: TeaSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TeaColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TeaSpacing.lg),
            Text('Filter Plants', style: TeaTypography.titleLarge),
            const SizedBox(height: TeaSpacing.md),
            Text('Coming soon - filter by growth stage, health, and more.',
                style: TeaTypography.bodyMedium,),
            const SizedBox(height: TeaSpacing.xl),
          ],
        ),
      ),
    );
  }
}
