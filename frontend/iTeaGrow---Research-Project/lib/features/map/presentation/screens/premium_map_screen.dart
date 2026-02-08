import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Premium Plantation Map Screen
class PremiumMapScreen extends ConsumerStatefulWidget {
  const PremiumMapScreen({super.key});

  @override
  ConsumerState<PremiumMapScreen> createState() => _PremiumMapScreenState();
}

class _PremiumMapScreenState extends ConsumerState<PremiumMapScreen> {
  String _selectedBlock = 'All';
  String _viewMode = 'health'; // health, growth, moisture
  bool _showLegend = true;

  final List<PlantationBlock> _blocks = [
    PlantationBlock(
      id: 'A',
      name: 'Block A',
      area: 2.5,
      plants: 3200,
      healthScore: 92,
      growthStage: 'P+2',
      moisture: 78,
      position: const Offset(0.2, 0.15),
      size: const Size(0.35, 0.25),
    ),
    PlantationBlock(
      id: 'B',
      name: 'Block B',
      area: 1.8,
      plants: 2850,
      healthScore: 87,
      growthStage: 'P+1',
      moisture: 72,
      position: const Offset(0.6, 0.12),
      size: const Size(0.3, 0.22),
    ),
    PlantationBlock(
      id: 'C',
      name: 'Block C',
      area: 2.2,
      plants: 3100,
      healthScore: 68,
      growthStage: 'P+3',
      moisture: 65,
      position: const Offset(0.15, 0.45),
      size: const Size(0.4, 0.28),
    ),
    PlantationBlock(
      id: 'D',
      name: 'Block D',
      area: 3.0,
      plants: 3300,
      healthScore: 95,
      growthStage: 'Bud',
      moisture: 82,
      position: const Offset(0.55, 0.42),
      size: const Size(0.38, 0.32),
    ),
  ];

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
          'Plantation Map',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showLegend ? Icons.info : Icons.info_outline,
              color: TeaColors.freshLeaf,
            ),
            onPressed: () => setState(() => _showLegend = !_showLegend),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: TeaColors.nearBlack),
            onSelected: (value) {
              if (value == 'refresh') {
                TeaSnackbar.info(context, 'Refreshing map data...');
              } else if (value == 'satellite') {
                TeaSnackbar.info(context, 'Satellite view coming soon!');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              const PopupMenuItem(value: 'satellite', child: Text('Satellite View')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Selector
          Container(
            padding: const EdgeInsets.all(TeaSpacing.md),
            color: TeaColors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildViewModeButton(
                    icon: Icons.health_and_safety,
                    label: 'Health',
                    mode: 'health',
                  ),
                ),
                const SizedBox(width: TeaSpacing.sm),
                Expanded(
                  child: _buildViewModeButton(
                    icon: Icons.grass,
                    label: 'Growth',
                    mode: 'growth',
                  ),
                ),
                const SizedBox(width: TeaSpacing.sm),
                Expanded(
                  child: _buildViewModeButton(
                    icon: Icons.water_drop,
                    label: 'Moisture',
                    mode: 'moisture',
                  ),
                ),
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: Stack(
              children: [
                // Map Background
                Container(
                  margin: TeaSpacing.screenPadding,
                  decoration: BoxDecoration(
                    color: TeaColors.white,
                    borderRadius: TeaRadius.radiusLg,
                    boxShadow: TeaShadows.cardShadowMedium,
                  ),
                  child: ClipRRect(
                    borderRadius: TeaRadius.radiusLg,
                    child: Stack(
                      children: [
                        // Grid lines
                        CustomPaint(
                          size: Size.infinite,
                          painter: GridPainter(),
                        ),

                        // Plantation blocks
                        ..._blocks.map((block) => _buildBlockOverlay(block)),

                        // Sensors
                        Positioned(
                          left: 50,
                          top: 80,
                          child: _buildSensorMarker('S1', true),
                        ),
                        Positioned(
                          right: 80,
                          top: 120,
                          child: _buildSensorMarker('S2', true),
                        ),
                        Positioned(
                          left: 100,
                          bottom: 100,
                          child: _buildSensorMarker('S3', false),
                        ),
                      ],
                    ),
                  ),
                ),

                // Legend
                if (_showLegend)
                  Positioned(
                    left: TeaSpacing.lg,
                    bottom: TeaSpacing.lg,
                    child: _buildLegend().animate().fadeIn().slideX(begin: -0.2),
                  ),

                // Block Info Card (when selected)
                if (_selectedBlock != 'All')
                  Positioned(
                    right: TeaSpacing.lg,
                    bottom: TeaSpacing.lg,
                    child: _buildBlockInfoCard(
                      _blocks.firstWhere((b) => b.id == _selectedBlock),
                    ).animate().fadeIn().slideX(begin: 0.2),
                  ),
              ],
            ),
          ),

          // Block Selector
          Container(
            padding: const EdgeInsets.all(TeaSpacing.md),
            color: TeaColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBlockChip('All', 'All Blocks', null),
                  ..._blocks.map((block) => _buildBlockChip(
                        block.id,
                        block.name,
                        _getBlockColor(block),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/iot-devices'),
        backgroundColor: TeaColors.freshLeaf,
        icon: const Icon(Icons.sensors, color: TeaColors.white),
        label: const Text('IoT Sensors', style: TextStyle(color: TeaColors.white)),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required String mode,
  }) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TeaSpacing.md,
          vertical: TeaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TeaColors.freshLeaf : TeaColors.lightGray,
          borderRadius: TeaRadius.radiusMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? TeaColors.white : TeaColors.darkGray,
            ),
            const SizedBox(width: TeaSpacing.xs),
            Text(
              label,
              style: TeaTypography.labelMedium.copyWith(
                color: isSelected ? TeaColors.white : TeaColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockOverlay(PlantationBlock block) {
    final isSelected = _selectedBlock == block.id;
    final color = _getBlockColor(block);

    return Positioned(
      left: block.position.dx * 300,
      top: block.position.dy * 400,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBlock = _selectedBlock == block.id ? 'All' : block.id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: block.size.width * 200,
          height: block.size.height * 200,
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.5 : 0.3),
            borderRadius: TeaRadius.radiusMd,
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.5),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  block.name,
                  style: TeaTypography.titleSmall.copyWith(
                    color: TeaColors.nearBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getBlockMetric(block),
                  style: TeaTypography.labelSmall.copyWith(
                    color: TeaColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorMarker(String id, bool isOnline) {
    return Tooltip(
      message: 'Sensor $id - ${isOnline ? 'Online' : 'Offline'}',
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: TeaColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isOnline ? TeaColors.healthyGreen : TeaColors.mediumGray,
            width: 2,
          ),
          boxShadow: TeaShadows.buttonShadow,
        ),
        child: Center(
          child: Icon(
            Icons.sensors,
            size: 16,
            color: isOnline ? TeaColors.healthyGreen : TeaColors.mediumGray,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return TeaCard.elevated(
      padding: TeaSpacing.cardPaddingSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _viewMode == 'health'
                ? 'Health Status'
                : _viewMode == 'growth'
                    ? 'Growth Stage'
                    : 'Moisture Level',
            style: TeaTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TeaSpacing.sm),
          if (_viewMode == 'health') ...[
            _buildLegendItem(TeaColors.healthyGreen, 'Excellent (90%+)'),
            _buildLegendItem(TeaColors.leafMedium, 'Good (70-89%)'),
            _buildLegendItem(TeaColors.warningAmber, 'Fair (50-69%)'),
            _buildLegendItem(TeaColors.alertRust, 'Poor (<50%)'),
          ] else if (_viewMode == 'growth') ...[
            _buildLegendItem(TeaColors.leafLight, 'Bud Stage'),
            _buildLegendItem(TeaColors.leafMedium, 'P+1'),
            _buildLegendItem(TeaColors.freshLeaf, 'P+2 (Harvest)'),
            _buildLegendItem(TeaColors.matureLeaf, 'P+3'),
          ] else ...[
            _buildLegendItem(TeaColors.infoSky, 'High (80%+)'),
            _buildLegendItem(TeaColors.leafMedium, 'Optimal (60-79%)'),
            _buildLegendItem(TeaColors.warningAmber, 'Low (40-59%)'),
            _buildLegendItem(TeaColors.alertRust, 'Critical (<40%)'),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color),
            ),
          ),
          const SizedBox(width: TeaSpacing.sm),
          Text(
            label,
            style: TeaTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockInfoCard(PlantationBlock block) {
    return TeaCard.elevated(
      padding: TeaSpacing.cardPaddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                block.name,
                style: TeaTypography.titleMedium,
              ),
              const SizedBox(width: TeaSpacing.sm),
              TeaStatusBadge(
                label: '${block.healthScore}%',
                color: _getHealthColor(block.healthScore),
              ),
            ],
          ),
          const SizedBox(height: TeaSpacing.sm),
          _buildInfoItem(Icons.straighten, '${block.area} hectares'),
          _buildInfoItem(Icons.eco, '${block.plants} plants'),
          _buildInfoItem(Icons.grass, 'Stage: ${block.growthStage}'),
          _buildInfoItem(Icons.water_drop, 'Moisture: ${block.moisture}%'),
          const SizedBox(height: TeaSpacing.sm),
          SizedBox(
            width: 150,
            child: TeaButton.primary(
              label: 'View Details',
              size: TeaButtonSize.small,
              onPressed: () => context.push('/plants'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TeaColors.darkGray),
          const SizedBox(width: TeaSpacing.xs),
          Text(
            text,
            style: TeaTypography.bodySmall.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockChip(String id, String label, Color? color) {
    final isSelected = _selectedBlock == id;
    return Padding(
      padding: const EdgeInsets.only(right: TeaSpacing.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: TeaSpacing.xs),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: TeaColors.leafPale,
        checkmarkColor: TeaColors.freshLeaf,
        onSelected: (_) => setState(() => _selectedBlock = id),
      ),
    );
  }

  Color _getBlockColor(PlantationBlock block) {
    if (_viewMode == 'health') {
      return _getHealthColor(block.healthScore);
    } else if (_viewMode == 'growth') {
      return _getGrowthColor(block.growthStage);
    } else {
      return _getMoistureColor(block.moisture);
    }
  }

  Color _getHealthColor(int score) {
    if (score >= 90) return TeaColors.healthyGreen;
    if (score >= 70) return TeaColors.leafMedium;
    if (score >= 50) return TeaColors.warningAmber;
    return TeaColors.alertRust;
  }

  Color _getGrowthColor(String stage) {
    switch (stage) {
      case 'Bud':
        return TeaColors.leafLight;
      case 'P+1':
        return TeaColors.leafMedium;
      case 'P+2':
        return TeaColors.freshLeaf;
      case 'P+3':
        return TeaColors.matureLeaf;
      default:
        return TeaColors.deepForest;
    }
  }

  Color _getMoistureColor(int moisture) {
    if (moisture >= 80) return TeaColors.infoSky;
    if (moisture >= 60) return TeaColors.leafMedium;
    if (moisture >= 40) return TeaColors.warningAmber;
    return TeaColors.alertRust;
  }

  String _getBlockMetric(PlantationBlock block) {
    if (_viewMode == 'health') {
      return '${block.healthScore}% health';
    } else if (_viewMode == 'growth') {
      return block.growthStage;
    } else {
      return '${block.moisture}% moisture';
    }
  }
}

class PlantationBlock {
  final String id;
  final String name;
  final double area;
  final int plants;
  final int healthScore;
  final String growthStage;
  final int moisture;
  final Offset position;
  final Size size;

  PlantationBlock({
    required this.id,
    required this.name,
    required this.area,
    required this.plants,
    required this.healthScore,
    required this.growthStage,
    required this.moisture,
    required this.position,
    required this.size,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TeaColors.lightGray.withOpacity(0.5)
      ..strokeWidth = 0.5;

    // Draw horizontal lines
    for (int i = 0; i <= 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
