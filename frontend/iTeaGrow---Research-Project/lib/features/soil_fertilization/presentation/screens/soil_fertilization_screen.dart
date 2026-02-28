import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../data/providers/soil_health_provider.dart';
import '../../domain/entities/soil_health_record.dart';
import 'soil_health_pdf_screen.dart';

class SoilFertilizationScreen extends ConsumerStatefulWidget {
  const SoilFertilizationScreen({super.key});

  @override
  ConsumerState<SoilFertilizationScreen> createState() =>
      _SoilFertilizationScreenState();
}

class _SoilFertilizationScreenState
    extends ConsumerState<SoilFertilizationScreen> {
  double _blockSize = 1.0; // In Hectares
  String _selectedZoneFilter = 'All'; // All, North, East, South, West, Central
  String _selectedHealthFilter = 'All'; // All, Good, Fair, Poor

  String _getZoneName(int id) {
    if (id <= 25) return 'North';
    if (id <= 50) return 'East';
    if (id <= 75) return 'South';
    if (id <= 100) return 'West';
    return 'Central';
  }

  String _getHectareLabel(int id) {
    return '${_getZoneName(id)} A$id';
  }

  @override
  Widget build(BuildContext context) {
    final soilState = ref.watch(soilHealthProvider);
    final record = soilState.latest;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8), // Airy off-white to match map
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background Gradient ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      const Color(0xFFF7FAF8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildPremiumHeader(record),
                  _buildHectareSelector(soilState),
                  if (soilState.isLoading && record == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (soilState.error != null && record == null)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(soilState.error!),
                      ),
                    )
                  else
                    _buildMainReport(record),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(SoilHealthRecord? record) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // _kShadowSoft
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 12),
            Text(
              'Soil Health Report',
              style: TeaTypography.headlineSmall.copyWith(
                color: TeaColors.deepForest,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 20,
              color: Colors.black.withOpacity(0.1),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              color: TeaColors.deepForest.withOpacity(0.8),
              onPressed: () => ref.read(soilHealthProvider.notifier).refresh(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            if (record != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 20,
                color: Colors.black.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                color: TeaColors.deepForest.withOpacity(0.8),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SoilHealthPdfScreen(record: record),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHectareSelector(SoilHealthState state) {
    if (state.records.isEmpty) return const SizedBox.shrink();

    // 1. Filter the records
    final filteredRecords = state.records.where((record) {
      final zoneMatch = _selectedZoneFilter == 'All' ||
          _getZoneName(record.hectareId) == _selectedZoneFilter;
      final healthMatch = _selectedHealthFilter == 'All' ||
          record.healthStatus.label == _selectedHealthFilter;
      return zoneMatch && healthMatch;
    }).toList();

    return Column(
      children: [
        // Zone Filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              'All',
              'North',
              'East',
              'South',
              'West',
              'Central',
            ].map((zone) {
              final isSelected = _selectedZoneFilter == zone;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(zone, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedZoneFilter = zone);
                  },
                  selectedColor: TeaColors.deepForest.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? TeaColors.deepForest : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Health Filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              'All',
              'Good',
              'Fair',
              'Poor',
            ].map((health) {
              final isSelected = _selectedHealthFilter == health;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(health, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedHealthFilter = health);
                  },
                  selectedColor: health == 'Good'
                      ? TeaColors.healthyGreen.withOpacity(0.2)
                      : health == 'Fair'
                          ? TeaColors.warningAmber.withOpacity(0.2)
                          : health == 'Poor'
                              ? TeaColors.alertRust.withOpacity(0.2)
                              : TeaColors.deepForest.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (health == 'Good'
                            ? TeaColors.healthyGreen
                            : health == 'Fair'
                                ? TeaColors.warningAmber
                                : health == 'Poor'
                                    ? TeaColors.alertRust
                                    : TeaColors.deepForest)
                        : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Hectare Chips
        SizedBox(
          height: 60,
          child: filteredRecords.isEmpty
              ? const Center(
                  child: Text('No hectares match these filters',
                      style: TextStyle(fontSize: 12, color: Colors.grey)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    final hectareId = record.hectareId;
                    final isSelected = state.selectedHectareId == hectareId;

                    return GestureDetector(
                      onTap: () => ref
                          .read(soilHealthProvider.notifier)
                          .selectHectare(hectareId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? TeaColors.deepForest : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? TeaColors.deepForest
                                : TeaColors.deepForest.withOpacity(0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: TeaColors.deepForest.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getHectareLabel(hectareId),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : TeaColors.deepForest,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMainReport(SoilHealthRecord? record) {
    if (record == null)
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Text('No data report generated'),
      ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Summary
          _buildExecutiveSummary(record),

          const SizedBox(height: 32),

          // 2. Critical Actions (Fertilizer)
          _buildActionsSection(record),

          const SizedBox(height: 32),

          // 3. Detailed Soil Metrics
          Text('Soil Chemistry Details', style: TeaTypography.titleLarge),
          const SizedBox(height: 16),
          _buildDetailedMetrics(record),

          const SizedBox(height: 32),

          // 4. Timestamp & Meta
          Center(
            child: Text(
              'Report generated at ${record.formattedTime} for ${_getHectareLabel(record.hectareId)}',
              style: TeaTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(SoilHealthRecord record) {
    final status = record.healthStatus;
    final color = _getStatusColor(status);
    final isGood = status == SoilHealthStatus.good;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SOIL CONDITION REPORT',
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.deepForest.withOpacity(0.5),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status.label.toUpperCase(),
            style: TeaTypography.displayMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isGood
                  ? 'Optimal condition. No major fertilizer adjustments required.'
                  : 'Action required. Significant imbalances found in Nitrogen/Soil Chemistry.',
              textAlign: TextAlign.center,
              style: TeaTypography.bodyMedium.copyWith(
                color: TeaColors.deepForest.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(SoilHealthRecord record) {
    final advice = record.sanitizedAdvice;
    if (advice.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Required Actions',
            style: TeaTypography.titleLarge.copyWith(
              color: TeaColors.deepForest,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...advice.map((line) => _buildPremiumActionCard(line)),
        const SizedBox(height: 16),
        _buildPremiumCalculator(record),
      ],
    );
  }

  Widget _buildPremiumActionCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TeaColors.warmAmber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded,
                color: TeaColors.warmAmber, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TeaTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: TeaColors.nearBlack.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCalculator(SoilHealthRecord record) {
    bool hasUreaCount = record.sanitizedAdvice.any((a) => a.contains('Urea'));
    if (!hasUreaCount) return const SizedBox.shrink();

    double bagsNeeded = (_blockSize * 50) / 50;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TeaColors.deepForest,
            TeaColors.deepForest.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: TeaColors.deepForest.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Procurement Estimator',
                style: TeaTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildModernChip(1.0),
              _buildModernChip(2.5),
              _buildModernChip(5.0),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bagsNeeded.ceil()} BAGS',
                    style: TeaTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'UREA REQ.',
                    style: TeaTypography.bodySmall.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernChip(double size) {
    bool isSelected = _blockSize == size;
    return GestureDetector(
      onTap: () => setState(() => _blockSize = size),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          '${size}ha',
          style: TextStyle(
            color: isSelected ? TeaColors.deepForest : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(SoilHealthRecord record) {
    return Column(
      children: [
        _buildMetricBar(
            'Nitrogen (N)', record.nitrogen, 150, 250, 'Sensor Level'),
        const SizedBox(height: 12),
        _buildMetricBar(
            'Phosphorus (P)', record.phosphorus, 80, 150, 'Sensor Level'),
        const SizedBox(height: 12),
        _buildMetricBar(
            'Potassium (K)', record.potassium, 150, 250, 'Sensor Level'),
        const SizedBox(height: 24),
        _buildMetricBar('Soil pH', record.ph, 4.5, 5.5, 'pH'),
        const SizedBox(height: 12),
        _buildMetricBar('Humidity', record.humidity, 40, 70, '%'),
      ],
    );
  }

  Widget _buildMetricBar(
      String label, double value, double min, double max, String unit) {
    final status = value < min
        ? 'Low'
        : value > max
            ? 'High'
            : 'Optimal';
    final color =
        status == 'Optimal' ? TeaColors.healthyGreen : TeaColors.alertRust;

    // Convert to percentage for user-friendly display
    final percentage = ((value / 1999) * 100).clamp(0, 100);
    final displayValue = unit == 'Sensor Level'
        ? '${percentage.toStringAsFixed(0)}%'
        : '${value.toStringAsFixed(1)} $unit';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TeaTypography.labelLarge.copyWith(
                  color: TeaColors.deepForest,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                displayValue,
                style: TeaTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Status: $status (Optimal Range: ${((min / 1999) * 100).toStringAsFixed(0)}-${((max / 1999) * 100).toStringAsFixed(0)}%)',
              style: TeaTypography.bodySmall.copyWith(
                color: Colors.black.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SoilHealthStatus status) {
    switch (status) {
      case SoilHealthStatus.good:
        return TeaColors.healthyGreen;
      case SoilHealthStatus.fair:
        return TeaColors.warningAmber;
      case SoilHealthStatus.poor:
        return TeaColors.alertRust;
      default:
        return Colors.grey;
    }
  }
}
