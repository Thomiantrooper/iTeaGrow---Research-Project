import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
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
  // Zone name from zone ID (1-5)
  String _zoneNameForId(int zoneId) {
    final l = AppLocalizations.of(context)!;
    final names = [l.zone_north, l.zone_east, l.zone_south, l.zone_west, l.zone_central];
    return names[(zoneId - 1).clamp(0, 4)];
  }

  // Zone name derived from a hectare_id (625 hectares per zone — matches the map screen)
  String _zoneNameForHectare(int hectareId) {
    final l = AppLocalizations.of(context)!;
    if (hectareId <= 625) return l.zone_north;
    if (hectareId <= 1250) return l.zone_east;
    if (hectareId <= 1875) return l.zone_south;
    if (hectareId <= 2500) return l.zone_west;
    return l.zone_central;
  }

  // Block display number B1-B25 from a block base hectare_id
  int _getBlockDisplayNum(int blockBase) {
    const zoneBases = [1, 626, 1251, 1876, 2501];
    for (final zb in zoneBases) {
      if (blockBase >= zb && blockBase < zb + 625) {
        return (blockBase - zb) ~/ 25 + 1;
      }
    }
    return 1;
  }

  // First hectare_id of a zone
  int _zoneBase(int zoneId) {
    const bases = [1, 626, 1251, 1876, 2501];
    return bases[(zoneId - 1).clamp(0, 4)];
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
    final state = ref.watch(soilHealthProvider);
    final notifier = ref.read(soilHealthProvider.notifier);
    final isNested = state.selectedZoneId != null;

    final l = AppLocalizations.of(context)!;
    String headerTitle = l.soil_report_title;
    if (state.selectedBlockId != null && state.selectedHectareId != null) {
      headerTitle =
          'B${_getBlockDisplayNum(state.selectedHectareId!)} · S${state.selectedBlockId} ${l.soil_analysis}';
    } else if (state.selectedHectareId != null) {
      headerTitle =
          '${l.soil_block} ${_getBlockDisplayNum(state.selectedHectareId!)} ${l.soil_analysis}';
    } else if (state.selectedZoneId != null) {
      headerTitle = '${_zoneNameForId(state.selectedZoneId!)} ${l.soil_zone_overview}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 48,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back arrow: exits screen at top level, goes up within hierarchy when nested
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: TeaColors.deepForest,
              onPressed: isNested
                  ? () => notifier.navigateUp()
                  : () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            if (!isNested) ...[
              const SizedBox(width: 8),
              const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 22),
            ],
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                headerTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TeaTypography.headlineSmall.copyWith(
                  color: TeaColors.deepForest,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
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
              onPressed: () => notifier.refresh(),
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
    if (state.selectedZoneId == null) {
      return _buildZoneSelector(state);
    } else if (state.selectedHectareId == null) {
      return _buildDivisionSelector(state);
    } else {
      return _buildSubDivisionSelector(state);
    }
  }

  Widget _buildZoneSelector(SoilHealthState state) {
    final l = AppLocalizations.of(context)!;
    final zones = [l.zone_north, l.zone_east, l.zone_south, l.zone_west, l.zone_central];
    final notifier = ref.read(soilHealthProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.soil_select_zone,
              style: TextStyle(
                color: TeaColors.deepForest.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              final zoneId = index + 1;

              return GestureDetector(
                onTap: () => notifier.selectZone(zoneId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: TeaColors.deepForest.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getZoneColor(zoneId),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        zone,
                        style: TextStyle(
                          color: TeaColors.deepForest,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDivisionSelector(SoilHealthState state) {
    final notifier = ref.read(soilHealthProvider.notifier);
    final zoneId = state.selectedZoneId!;
    // Block bases: 25 blocks per zone, each block spans 25 consecutive hectare_ids.
    // Matches the map screen's _createSubZones() zone base offsets.
    final zoneBase = _zoneBase(zoneId);
    final blockBases = List.generate(25, (i) => zoneBase + i * 25);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppLocalizations.of(context)!.soil_select_block} (${_zoneNameForId(zoneId)} ${AppLocalizations.of(context)!.zone_label})',
              style: TextStyle(
                color: TeaColors.deepForest.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: blockBases.length,
            itemBuilder: (context, index) {
              final blockBase = blockBases[index];
              final displayNum = index + 1; // B1–B25
              // Block has data when ANY of its 25 sectors has a record
              final blockRecords = state.records
                  .where((r) =>
                      r.hectareId >= blockBase && r.hectareId <= blockBase + 24)
                  .toList();
              final hasData = blockRecords.isNotEmpty;
              final isSelected = state.selectedHectareId == blockBase;

              // Health color based on most recent record in this block
              Color statusColor = TeaColors.mediumGray.withOpacity(0.1);
              if (hasData) {
                blockRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                final status = blockRecords.first.healthStatus;
                if (status == SoilHealthStatus.good) {
                  statusColor = TeaColors.healthyGreen.withOpacity(0.15);
                } else if (status == SoilHealthStatus.fair) {
                  statusColor = TeaColors.warningAmber.withOpacity(0.15);
                } else {
                  statusColor = TeaColors.alertRust.withOpacity(0.15);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('B$displayNum'),
                      if (hasData) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : _getStatusColor(
                                    blockRecords.first.healthStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: () => notifier.selectHectare(blockBase),
                  backgroundColor:
                      isSelected ? TeaColors.deepForest : statusColor,
                  side: BorderSide(
                      color: isSelected
                          ? TeaColors.deepForest
                          : TeaColors.deepForest.withOpacity(0.1)),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : TeaColors.deepForest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubDivisionSelector(SoilHealthState state) {
    final notifier = ref.read(soilHealthProvider.notifier);
    // blockBase = selectedHectareId (block's first hectare_id).
    // S1 = blockBase+0, S2 = blockBase+1, ..., S25 = blockBase+24.
    final blockBase = state.selectedHectareId!;
    final blockDisplayNum = _getBlockDisplayNum(blockBase);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppLocalizations.of(context)!.soil_select_sector} B$blockDisplayNum',
              style: TextStyle(
                color: TeaColors.deepForest.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 25,
            itemBuilder: (context, index) {
              final sIdx = index + 1; // Sector number S1-S25
              final sectorHId = blockBase + index; // actual hectare_id in DB
              final isSelected = state.selectedBlockId == sIdx;
              final record = state.records
                  .where((r) => r.hectareId == sectorHId)
                  .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final hasData = record.isNotEmpty;
              // Always use the most recent read (newest scan round first)
              final latestRecord = hasData ? record.first : null;

              Color statusColor = TeaColors.mediumGray.withOpacity(0.1);
              if (hasData) {
                final status = latestRecord!.healthStatus;
                if (status == SoilHealthStatus.good) {
                  statusColor = TeaColors.healthyGreen.withOpacity(0.1);
                } else if (status == SoilHealthStatus.fair) {
                  statusColor = TeaColors.warningAmber.withOpacity(0.1);
                } else {
                  statusColor = TeaColors.alertRust.withOpacity(0.1);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('S$sIdx'),
                      if (hasData) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : _getStatusColor(latestRecord!.healthStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) notifier.selectBlock(sIdx);
                  },
                  backgroundColor: statusColor,
                  selectedColor: TeaColors.deepForest,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : TeaColors.deepForest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getZoneColor(int zoneId) {
    switch (zoneId) {
      case 1:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFE53935);
      case 3:
        return const Color(0xFF43A047);
      case 4:
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFFFB300);
    }
  }

  Widget _buildMainReport(SoilHealthRecord? record) {
    if (record == null)
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(AppLocalizations.of(context)!.soil_no_data),
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
          Text(AppLocalizations.of(context)!.soil_chemistry_details, style: TeaTypography.titleLarge),
          const SizedBox(height: 16),
          _buildDetailedMetrics(record),

          const SizedBox(height: 32),

          // 4. Timestamp & Meta
          Center(
            child: Text(
              _selectedHectareLabel(record),
              style: TeaTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          // ── Sequential Survey Navigation ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(soilHealthProvider.notifier).selectPrevious(),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(AppLocalizations.of(context)!.soil_prev_block),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(soilHealthProvider.notifier).selectNext(),
                  icon: const Icon(Icons.chevron_right),
                  label: Text(AppLocalizations.of(context)!.soil_next_block),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeaColors.deepForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
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
            AppLocalizations.of(context)!.soil_condition_label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.deepForest.withOpacity(0.5),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _localizeSoilHealthStatus(status, AppLocalizations.of(context)!).toUpperCase(),
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
                  ? AppLocalizations.of(context)!.soil_optimal_msg
                  : AppLocalizations.of(context)!.soil_action_msg,
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
            AppLocalizations.of(context)!.soil_required_actions,
            style: TeaTypography.titleLarge.copyWith(
              color: TeaColors.deepForest,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...advice.map((line) => _buildPremiumActionCard(_localizeFertilizerRec(line, AppLocalizations.of(context)!))),
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

  Widget _buildDetailedMetrics(SoilHealthRecord record) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildMetricBar(
            l.soil_nitrogen, record.nitrogen, 150, 250, l.soil_sensor_level),
        const SizedBox(height: 12),
        _buildMetricBar(
            l.soil_phosphorus, record.phosphorus, 80, 150, l.soil_sensor_level),
        const SizedBox(height: 12),
        _buildMetricBar(
            l.soil_potassium, record.potassium, 150, 250, l.soil_sensor_level),
        const SizedBox(height: 24),
        _buildMetricBar(l.soil_ph, record.ph, 4.5, 5.5, 'pH'),
        const SizedBox(height: 12),
        _buildMetricBar(l.soil_humidity, record.humidity, 40, 70, '%'),
      ],
    );
  }

  Widget _buildMetricBar(
      String label, double value, double min, double max, String unit) {
    final l = AppLocalizations.of(context)!;
    final statusLabel = value < min
        ? l.soil_status_low
        : value > max
            ? l.soil_status_high
            : l.soil_status_optimal;
    final color =
        statusLabel == l.soil_status_optimal ? TeaColors.healthyGreen : TeaColors.alertRust;

    // Convert to percentage for user-friendly display
    final percentage = ((value / 1999) * 100).clamp(0, 100);
    final displayValue = unit == l.soil_sensor_level
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
              '${l.soil_status_label}: $statusLabel (${l.soil_optimal_range}: ${((min / 1999) * 100).toStringAsFixed(0)}-${((max / 1999) * 100).toStringAsFixed(0)}%)',
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

  String _selectedHectareLabel(SoilHealthRecord record) {
    final state = ref.read(soilHealthProvider);
    final l = AppLocalizations.of(context)!;
    final zoneName = _zoneNameForHectare(record.hectareId);
    if (state.selectedBlockId != null && state.selectedHectareId != null) {
      final blockNum = _getBlockDisplayNum(state.selectedHectareId!);
      return '${l.soil_report_for} $zoneName B$blockNum · S${state.selectedBlockId} ${l.soil_at} ${record.formattedTime}';
    }
    if (state.selectedHectareId != null) {
      final blockNum = _getBlockDisplayNum(state.selectedHectareId!);
      return '${l.soil_report_for} $zoneName B$blockNum ${l.soil_at} ${record.formattedTime}';
    }
    return '${l.soil_report_for} $zoneName S${record.hectareId} ${l.soil_at} ${record.formattedTime}';
  }

  String _localizeSoilHealthStatus(SoilHealthStatus status, AppLocalizations l10n) {
    switch (status) {
      case SoilHealthStatus.good:
        return l10n.soil_health_good;
      case SoilHealthStatus.fair:
        return l10n.soil_health_fair;
      case SoilHealthStatus.poor:
        return l10n.soil_health_poor;
      default:
        return l10n.soil_health_unknown;
    }
  }

  String _localizeFertilizerRec(String rec, AppLocalizations l10n) {
    final c = rec.replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u00FF]'), '').trim();
    if (c.contains('nitrogen fertilizer')) return l10n.soil_rec_n_low;
    if (c.contains('phosphorus fertilizer')) return l10n.soil_rec_p_low;
    if (c.contains('potassium fertilizer')) return l10n.soil_rec_k_low;
    if (c.contains('lime to increase pH')) return l10n.soil_rec_ph_low;
    if (c.contains('organic matter addition') && !c.contains('amendment')) return l10n.soil_rec_ec_low;
    if (c.toLowerCase().contains('soil temperature low')) return l10n.soil_rec_temp_low;
    if (c.contains('Irrigation needed')) return l10n.soil_rec_humidity_low;
    if (c.toUpperCase().contains('REDUCE') && c.toLowerCase().contains('nitrogen')) return l10n.soil_rec_n_high;
    if (c.toUpperCase().contains('REDUCE') && c.toLowerCase().contains('phosphorus')) return l10n.soil_rec_p_high;
    if (c.toUpperCase().contains('REDUCE') && c.toLowerCase().contains('potassium')) return l10n.soil_rec_k_high;
    if (c.contains('sulfur to lower pH')) return l10n.soil_rec_ph_high;
    if (c.contains('salinity')) return l10n.soil_rec_ec_high;
    if (c.toLowerCase().contains('temperature too high')) return l10n.soil_rec_temp_high;
    if (c.toLowerCase().contains('humidity too high')) return l10n.soil_rec_humidity_high;
    if (c.toLowerCase().contains('maintain current')) return l10n.soil_rec_maintain;
    if (c.contains('health is optimal')) return l10n.soil_rec_soil_good;
    if (c.contains('health is poor') || c.contains('detailed soil analysis')) return l10n.soil_rec_poor_general;
    if (c.contains('soil amendment')) return l10n.soil_rec_amendment;
    return c;
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
