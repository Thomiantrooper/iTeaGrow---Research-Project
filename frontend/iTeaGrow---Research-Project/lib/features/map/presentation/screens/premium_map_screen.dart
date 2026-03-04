import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:iteagrow/features/map/domain/models/iot_zone_models.dart';
import 'package:iteagrow/features/map/presentation/providers/iot_map_provider.dart';
import 'package:iteagrow/core/design_system/tea_colors.dart';
import 'package:iteagrow/core/design_system/tea_typography.dart';

class PremiumMapScreen extends ConsumerStatefulWidget {
  const PremiumMapScreen({super.key});

  @override
  ConsumerState<PremiumMapScreen> createState() => _PremiumMapScreenState();
}

// ── Premium Light Mode Design Tokens ──────────────────────────────────
const _kPrimaryDeep = Color(0xFF1A3D2B); // Deep charcoal-green
const _kShadowSoft = Color(0x1A000000); // 10% black shadow

class _PremiumMapScreenState extends ConsumerState<PremiumMapScreen>
    with TickerProviderStateMixin {
  List<PlantationZone> _zones = [];
  List<SoilData> _allSoilData = []; // Store full API response
  SoilData? _selectedHectare;
  int? _selectedZoneId;
  int? _selectedHectareId; // Level 4 navigation state
  late AnimationController _pulseController;

  // Search & division filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Auto-refresh
  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshed;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeZones();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Auto-refresh every 5 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _triggerRefresh();
    });
    _lastRefreshed = DateTime.now();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    ref.invalidate(latestSoilDataProvider);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _lastRefreshed = DateTime.now();
      });
    }
  }

  String _formatLastRefreshed() {
    if (_lastRefreshed == null) return 'Never';
    final diff = DateTime.now().difference(_lastRefreshed!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  void _initializeZones() {
    // Defines custom polygonal points for the map. Values are relative (0.0 - 1.0)
    _zones = [
      PlantationZone(
        id: 1,
        name: 'North Zone',
        accentColor: const Color(0xFFE53935), // Red
        position: const Offset(0.3, 0.2),
        size: const Size(0.4, 0.3),
        // Zone base hectare_id = 1 → B1 covers h_id 1-25, B2 covers 26-50, ...
        subZones: _createSubZones(1, 1),
      ),
      PlantationZone(
        id: 2,
        name: 'East Zone',
        accentColor: const Color(0xFFE53935), // Red
        position: const Offset(0.7, 0.5),
        size: const Size(0.25, 0.3),
        subZones: _createSubZones(2, 626),
      ),
      PlantationZone(
        id: 3,
        name: 'South Zone',
        accentColor: const Color(0xFF43A047), // Green
        position: const Offset(0.5, 0.8),
        size: const Size(0.5, 0.2),
        subZones: _createSubZones(3, 1251),
      ),
      PlantationZone(
        id: 4,
        name: 'West Zone',
        accentColor: const Color(0xFF43A047), // Green
        position: const Offset(0.2, 0.6),
        size: const Size(0.3, 0.4),
        subZones: _createSubZones(4, 1876),
      ),
      PlantationZone(
        id: 5,
        name: 'Central Zone',
        accentColor: const Color(0xFFFFB300), // Yellow
        position: const Offset(0.45, 0.55),
        size: const Size(0.4, 0.3),
        subZones: _createSubZones(5, 2501),
      ),
    ];
  }

  /// Creates 25 sub-zones (blocks) for a zone.
  /// [zoneBase] is the starting hectare_id for Block 1 of this zone.
  /// Each block covers 25 sequential hectare_ids:
  ///   B1 = zoneBase to zoneBase+24
  ///   B2 = zoneBase+25 to zoneBase+49  ... etc.
  List<SubZone> _createSubZones(int zoneId, int zoneBase) {
    return List.generate(25, (blockIndex) {
      // hectareId here is the BLOCK BASE — the starting h_id of this block
      final blockBaseId = zoneBase + blockIndex * 25;
      final row = blockIndex ~/ 5;
      final col = blockIndex % 5;
      return SubZone(
        hectareId: blockBaseId,
        name: 'Block ${blockIndex + 1}',
        zoneId: zoneId,
        position: Offset(col * 0.2, row * 0.2),
        size: const Size(0.18, 0.18),
        latestData: null,
      );
    });
  }

  void _updateZonesWithData(List<SoilData> soilDataList) {
    // ALWAYS replace with what the API returns — stale in-memory data must not
    // survive a DB wipe. Block-range loaded sectors (_loadHectareData) are kept
    // only if they are for hectare_ids NOT present in the fresh API response.
    final freshIds = soilDataList.map((d) => d.hectareId).toSet();
    // Drop everything that the API now covers (could be empty after a DB drop)
    _allSoilData.removeWhere((d) =>
        freshIds.isEmpty || freshIds.contains(d.hectareId));
    // If the API returned nothing at all, wipe everything
    if (soilDataList.isEmpty) {
      _allSoilData = [];
    } else {
      // Merge fresh records (newer wins)
      final Map<int, SoilData> merged = {
        for (var d in _allSoilData) d.hectareId: d,
      };
      for (var d in soilDataList) {
        final existing = merged[d.hectareId];
        if (existing == null || d.timestamp.isAfter(existing.timestamp)) {
          merged[d.hectareId] = d;
        }
      }
      _allSoilData = merged.values.toList();
    }

    // Color each BLOCK (subZone) if ANY of its 25 sector slots have data.
    // subZone.hectareId = blockBase; the 25 sectors = blockBase to blockBase+24.
    for (var zone in _zones) {
      for (var subZone in zone.subZones) {
        final blockEnd = subZone.hectareId + 24;
        final blockRecords = _allSoilData
            .where((d) =>
                d.hectareId >= subZone.hectareId && d.hectareId <= blockEnd)
            .toList();
        if (blockRecords.isNotEmpty) {
          blockRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          subZone.latestData = blockRecords.first;
        } else {
          subZone.latestData = null;
        }
      }
    }
  }

  /// Load all 25 sector records for a block.
  /// [blockBase] = subZone.hectareId (the starting hectare_id of the block).
  Future<void> _loadHectareData(int blockBase) async {
    try {
      final blockEnd = blockBase + 24;
      final blockData = await ref
          .read(blockRangeProvider((start: blockBase, end: blockEnd)).future);

      if (mounted) {
        setState(() {
          // Replace any existing data in this block range
          _allSoilData.removeWhere(
              (d) => d.hectareId >= blockBase && d.hectareId <= blockEnd);
          _allSoilData.addAll(blockData);

          // Refresh the block's color
          for (var zone in _zones) {
            for (var subZone in zone.subZones) {
              if (subZone.hectareId == blockBase) {
                final records = blockData;
                if (records.isNotEmpty) {
                  records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  subZone.latestData = records.first;
                } else {
                  subZone.latestData = null;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      // silently fail — sectors will just stay grey for this block
    }
  }

  @override
  Widget build(BuildContext context) {
    final soilDataAsync = ref.watch(latestSoilDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8), // Airy off-white
      body: SafeArea(
        child: soilDataAsync.when(
          data: (soilDataList) {
            _updateZonesWithData(soilDataList);
            // Filter by search query (hectare id or zone name)
            final filtered = _searchQuery.isEmpty
                ? soilDataList
                : soilDataList.where((d) {
                    final zoneName =
                        _getZoneNameForHectare(d.hectareId).toLowerCase();
                    return d.hectareId.toString().contains(_searchQuery) ||
                        zoneName.contains(_searchQuery) ||
                        (d.soilHealth.toLowerCase().contains(_searchQuery));
                  }).toList();
            return _buildMapView(filtered, soilDataList);
          },
          loading: () => _buildLoadingView(),
          error: (error, stack) => _buildErrorView(error.toString()),
        ),
      ),
    );
  }

  Widget _buildMapView(List<SoilData> filtered, List<SoilData> soilDataList) {
    final Map<String, dynamic> stats = _calculateStatistics(soilDataList);

    return Stack(
      children: [
        // Plantation Map Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/Plantation Map.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to dark green if image not found
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2D5A3D),
                      Color(0xFF1A3D2B),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Semi-transparent overlay for better contrast
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),

        // Custom drawn polygons for the overview map OR the grid for the zoomed zone
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.0,
            child: _selectedZoneId == null
                ? _buildOverviewMapLayer()
                : _selectedHectareId == null
                    ? _buildDivisionGridLayer()
                    : _buildSubDivisionGridLayer(),
          ),
        ),

        // Controls Overlay
        Column(
          children: [
            if (_selectedZoneId == null)
              _buildOverviewHeader(stats)
            else
              _buildZoomedHeader(),
          ],
        ),

        // Side floating Card (Overview)
        if (_selectedZoneId == null)
          Positioned(
            left: 20,
            bottom: 30,
            child: _buildLegendCard(),
          ),

        // Bottom Sheet
        if (_selectedHectare != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildDetailsSheet(_selectedHectare!),
          ),
      ],
    );
  }

  Widget _buildOverviewHeader(Map<String, dynamic> stats) {
    return Column(
      children: [
        // ── Top "Floating Island" Header ──────────────────────────────────
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [
                BoxShadow(
                  color: _kShadowSoft,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spa_rounded,
                    color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                Text(
                  'Plantation Map',
                  style: TeaTypography.headlineSmall.copyWith(
                    color: _kPrimaryDeep,
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
                _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF43A047),
                        ),
                      )
                    : GestureDetector(
                        onTap: _triggerRefresh,
                        child: Icon(
                          Icons.refresh_rounded,
                          color: _kPrimaryDeep.withOpacity(0.8),
                          size: 22,
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ── Floating Quick-Action Stats Bubble Shelf ────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCreativeStatBubble(
                icon: Icons.eco_rounded,
                label: 'Healthy',
                count: stats['healthy'],
                color: const Color(0xFF43A047),
              ),
              const SizedBox(width: 12),
              _buildCreativeStatBubble(
                icon: Icons.sensors_rounded,
                label: 'Active',
                count: stats['active'],
                color: const Color(0xFF1976D2),
              ),
              const SizedBox(width: 12),
              _buildCreativeStatBubble(
                icon: Icons.crisis_alert_rounded,
                label: 'Critical',
                count: stats['alerts'],
                color: const Color(0xFFE53935),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreativeStatBubble({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: _kShadowSoft,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: _kPrimaryDeep,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomedHeader() {
    final zone = _zones.firstWhere((z) => z.id == _selectedZoneId);
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: _kShadowSoft,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => setState(() {
                if (_selectedHectareId != null) {
                  _selectedHectareId = null;
                } else {
                  _selectedZoneId = null;
                }
                _selectedHectare = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF2E7D32),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Zone Title & Info
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedHectareId != null
                      ? '${zone.name} > Block ${_getDisplayBlockNumber(_selectedHectareId!)}'
                      : zone.name,
                  style: TeaTypography.headlineSmall.copyWith(
                    color: _kPrimaryDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _selectedHectareId != null
                      ? 'Sub-division mapping • 25 sectors'
                      : '25 divisions • live monitoring',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Refresh Icon
            _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF43A047),
                    ),
                  )
                : GestureDetector(
                    onTap: _triggerRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: _kPrimaryDeep.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: _kShadowSoft,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: _kPrimaryDeep,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          _buildLegendRow(TeaColors.healthyGreen, 'Good — Healthy Soil'),
          const SizedBox(height: 10),
          _buildLegendRow(TeaColors.warningAmber, 'Fair — Needs Attention'),
          const SizedBox(height: 10),
          _buildLegendRow(const Color(0xFFE53935), 'Poor — Critical Status'),
          const SizedBox(height: 10),
          _buildLegendRow(
              TeaColors.mediumGray.withOpacity(0.5), 'No Data / Offline'),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMapLayer() {
    final screenSize = MediaQuery.of(context).size;
    final mapWidth = screenSize.width;
    final mapHeight = screenSize.height * 0.6;
    final outerRadius = math.min(mapWidth, mapHeight) * 0.42;
    final innerRadius = outerRadius * 0.30;

    return Center(
      child: SizedBox(
        width: mapWidth,
        height: mapHeight,
        child: GestureDetector(
          onTapUp: (details) {
            final center = Offset(mapWidth / 2, mapHeight / 2);
            final tap = details.localPosition;
            final dx = tap.dx - center.dx;
            final dy = tap.dy - center.dy;
            final dist = math.sqrt(dx * dx + dy * dy);

            if (dist > outerRadius) return; // Outside circle

            if (dist <= innerRadius) {
              setState(() => _selectedZoneId = 5); // Central
              return;
            }

            // Determine segment by angle
            final angle = math.atan2(dy, dx); // -π to π
            if (angle >= -3 * math.pi / 4 && angle < -math.pi / 4) {
              setState(() => _selectedZoneId = 1); // North
            } else if (angle >= -math.pi / 4 && angle < math.pi / 4) {
              setState(() => _selectedZoneId = 2); // East
            } else if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) {
              setState(() => _selectedZoneId = 3); // South
            } else {
              setState(() => _selectedZoneId = 4); // West
            }
          },
          child: CustomPaint(
            size: Size(mapWidth, mapHeight),
            painter: RadialZonePainter(
              zones: _zones,
              selectedZoneId: _selectedZoneId,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionGridLayer() {
    final zone = _zones.firstWhere((z) => z.id == _selectedZoneId);
    final size = MediaQuery.of(context).size;
    // subZones are already in order: B1 (base=zoneBase), B2 (base=zoneBase+25) ...
    // No sorting needed — order is fixed by the zone's block sequence.

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: size.width,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.85,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: zone.subZones.length,
          itemBuilder: (context, index) {
            final subZone = zone.subZones[index];
            final displayBlockNum = index + 1; // B1, B2, B3 ...
            final isSelected = _selectedHectareId == subZone.hectareId;
            final healthColor = subZone.healthColor;
            return GestureDetector(
              onTap: () async {
                setState(() {
                  _selectedHectareId = subZone.hectareId;
                });
                // Load hectare-specific data when selected
                await _loadHectareData(subZone.hectareId);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? healthColor
                      : healthColor.withValues(alpha: 0.85),
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isSelected ? 0.3 : 0.15),
                      blurRadius: isSelected ? 8 : 3,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'B$displayBlockNum',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubDivisionGridLayer() {
    final size = MediaQuery.of(context).size;
    // _selectedHectareId is the BLOCK BASE hectare_id (e.g. 1 for B1 of North)
    // S1 = hectare_id: blockBase+0, S2 = blockBase+1, ..., S25 = blockBase+24
    final blockBase = _selectedHectareId!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: size.width,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.85,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            final sectorNum = index + 1; // S1-S25
            final sectorHectareId = blockBase + index; // direct h_id for this sector
            // Most-recent record stored at this exact hectare_id
            final sectorData = _allSoilData
                .where((d) => d.hectareId == sectorHectareId)
                .fold<SoilData?>(
                    null,
                    (best, d) => best == null ||
                            d.timestamp.isAfter(best.timestamp)
                        ? d
                        : best);
            final isSelected =
                _selectedHectare?.hectareId == sectorHectareId;
            final healthColor = sectorData != null
                ? _soilHealthToColor(sectorData.soilHealth)
                : TeaColors.mediumGray.withValues(alpha: 0.3);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedHectare = sectorData; // null = grey sector (no data)
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? healthColor
                      : healthColor.withValues(alpha: 0.8),
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'S$sectorNum',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Map soil_health string → display color
  Color _soilHealthToColor(String health) {
    switch (health) {
      case 'Good':
        return TeaColors.healthyGreen;
      case 'Fair':
        return TeaColors.warningAmber;
      case 'Poor':
        return TeaColors.alertRust;
      default:
        return TeaColors.mediumGray;
    }
  }

  /// Block display number: subZone list index + 1 (B1, B2, B3...)
  /// [blockBaseHectareId] = subZone.hectareId (block's starting h_id)
  int _getDisplayBlockNumber(int blockBaseHectareId) {
    for (var zone in _zones) {
      final idx =
          zone.subZones.indexWhere((s) => s.hectareId == blockBaseHectareId);
      if (idx >= 0) return idx + 1;
    }
    return 1;
  }

  /// Sector display number: data.hectareId - blockBase + 1 (S1, S2, S3...)
  int _getSectorDisplayNumber(SoilData data) {
    for (var zone in _zones) {
      for (var subZone in zone.subZones) {
        if (data.hectareId >= subZone.hectareId &&
            data.hectareId <= subZone.hectareId + 24) {
          return data.hectareId - subZone.hectareId + 1;
        }
      }
    }
    return data.hectareId;
  }

  void _triggerSubHectareSelection(int sectorIndex) {
    // sectorIndex is 0-based within the block (0=S1, 1=S2, ...)
    // Direct mapping: sectorHectareId = blockBase + sectorIndex
    final sectorHectareId = _selectedHectareId! + sectorIndex;
    _selectedHectare = _allSoilData
        .where((d) => d.hectareId == sectorHectareId)
        .fold<SoilData?>(
            null,
            (best, d) => best == null || d.timestamp.isAfter(best.timestamp)
                ? d
                : best);
  }

  Widget _buildDetailsSheet(SoilData data) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.black54),
                        onPressed: () {
                          setState(() {
                            // Navigate between sectors that have data in this block
                            final blockBase = _selectedHectareId!;
                            final sectorsWithData = _allSoilData
                                .where((d) =>
                                    d.hectareId >= blockBase &&
                                    d.hectareId <= blockBase + 24)
                                .toList()
                              ..sort((a, b) =>
                                  a.hectareId.compareTo(b.hectareId));
                            if (sectorsWithData.isEmpty) return;
                            final curIdx = sectorsWithData.indexWhere(
                                (d) => d.hectareId == data.hectareId);
                            final prevIdx = curIdx <= 0
                                ? sectorsWithData.length - 1
                                : curIdx - 1;
                            _selectedHectare = sectorsWithData[prevIdx];
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedHectareId != null
                              ? 'B${_getDisplayBlockNumber(_selectedHectareId!)} · S${_getSectorDisplayNumber(data)}'
                              : 'Division ${data.hectareId}',
                          style: TeaTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.black54),
                        onPressed: () {
                          setState(() {
                            // Navigate between sectors that have data in this block
                            final blockBase = _selectedHectareId!;
                            final sectorsWithData = _allSoilData
                                .where((d) =>
                                    d.hectareId >= blockBase &&
                                    d.hectareId <= blockBase + 24)
                                .toList()
                              ..sort((a, b) =>
                                  a.hectareId.compareTo(b.hectareId));
                            if (sectorsWithData.isEmpty) return;
                            final curIdx = sectorsWithData.indexWhere(
                                (d) => d.hectareId == data.hectareId);
                            final nextIdx =
                                curIdx >= sectorsWithData.length - 1
                                    ? 0
                                    : curIdx + 1;
                            _selectedHectare = sectorsWithData[nextIdx];
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedHectare = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Smart Health Consensus Card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getHealthColor(data.soilHealth).withOpacity(0.12),
                    _getHealthColor(data.soilHealth).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getHealthColor(data.soilHealth).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        data.soilHealth == 'Good'
                            ? Icons.check_circle_rounded
                            : data.soilHealth == 'Fair'
                                ? Icons.error_outline_rounded
                                : Icons.warning_amber_rounded,
                        color: _getHealthColor(data.soilHealth),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        data.soilHealth.toUpperCase(),
                        style: TextStyle(
                          color: _getHealthColor(data.soilHealth),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVerificationBadge('ML ENGINE', Icons.auto_graph),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 1,
                          height: 14,
                          color: Colors.black12,
                        ),
                        _buildVerificationBadge(
                            'TRI STANDARDS', Icons.verified_user),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Soil Data Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A3A2A),
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              Icons.water_drop,
              'Soil Moisture: ${data.humidity.toStringAsFixed(1)}%',
            ),
            _buildDetailItem(
              Icons.science,
              'pH Level: ${data.pH.toStringAsFixed(2)} (Optimal: 4.5-5.5)',
            ),
            _buildDetailItem(
              Icons.grass,
              _getNPKDescription('Nitrogen (N)', data.nitrogen,
                  _getNitrogenStatus(data.nitrogen)),
            ),
            _buildDetailItem(
              Icons.energy_savings_leaf,
              _getNPKDescription('Phosphorus (P)', data.phosphorus,
                  _getPhosphorusStatus(data.phosphorus)),
            ),
            _buildDetailItem(
              Icons.nature,
              _getNPKDescription('Potassium (K)', data.potassium,
                  _getPotassiumStatus(data.potassium)),
            ),
            _buildDetailItem(
              Icons.flash_on,
              'Electrical Conductivity: ${(data.ec * 1000).toStringAsFixed(0)} μS/cm ${_getECStatus(data.ec * 1000)}',
            ),
            _buildDetailItem(Icons.thermostat,
                'Temperature: ${data.temperature.toStringAsFixed(1)}°C ${_getTempStatus(data.temperature)}'),
            const SizedBox(height: 16),
            const Text(
              'Recommendations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            if (data.fertilizer.isEmpty)
              const Text(
                '• No recommendations available.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            else
              ...data.fertilizer.map((rec) => _buildRecommendationItem(rec)),
            const SizedBox(height: 16),
            Text(
              'Last Updated: ${intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(data.timestamp.toLocal())}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    // Determine color based on status keywords
    Color backgroundColor = const Color(0xFFF5F9F6);
    Color borderColor = const Color(0xFFDDEEE4);
    Color iconColor = Colors.green.shade700;

    if (text.contains('Excessive') ||
        text.contains('Too High') ||
        text.contains('Too Hot')) {
      backgroundColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFFFB74D);
      iconColor = const Color(0xFFF57C00);
    } else if (text.contains('Slightly High') ||
        text.contains('High') ||
        text.contains('Warm')) {
      backgroundColor = const Color(0xFFFFF9E6);
      borderColor = const Color(0xFFFFE082);
      iconColor = const Color(0xFFFFA726);
    } else if (text.contains('Low') || text.contains('Cool')) {
      backgroundColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF90CAF9);
      iconColor = const Color(0xFF1976D2);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    final isWarning = recommendation.toUpperCase().contains('REDUCE') ||
        recommendation.toUpperCase().contains('EXCESS') ||
        recommendation.toUpperCase().contains('HIGH') ||
        recommendation.toUpperCase().contains('IMPROVE') ||
        recommendation.toUpperCase().contains('LOWER');

    // Sanitize string to remove any embedded emojis (like the ⚠️ that comes from DB)
    final cleanRegex = RegExp(r'[^\x20-\x7E\u00A0-\u00FF]');
    final cleanRecommendation =
        recommendation.replaceAll(cleanRegex, '').trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarning ? const Color(0xFFFFB74D) : const Color(0xFFDDEEE4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            size: 16,
            color:
                isWarning ? const Color(0xFFF57C00) : const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cleanRecommendation,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods

  Color _getHealthColor(String? healthStatus) {
    if (healthStatus == null) return TeaColors.mediumGray.withOpacity(0.3);

    final status = healthStatus.toLowerCase();
    if (status.contains('excellent') || status.contains('good')) {
      return TeaColors.healthyGreen;
    } else if (status.contains('fair')) {
      return TeaColors.warningAmber;
    } else if (status.contains('poor') || status.contains('critical')) {
      return TeaColors.alertRust;
    }
    return TeaColors.mediumGray;
  }

  // NPK Status helpers for tea cultivation (sensor raw values 0-1999)
  String _getNitrogenStatus(double n) {
    if (n < 150) return 'Low';
    if (n <= 250) return 'Optimal';
    if (n <= 400) return 'Slightly High';
    return 'Excessive';
  }

  String _getPhosphorusStatus(double p) {
    if (p < 80) return 'Low';
    if (p <= 150) return 'Optimal';
    if (p <= 300) return 'Slightly High';
    return 'Excessive';
  }

  String _getPotassiumStatus(double k) {
    if (k < 150) return 'Low';
    if (k <= 250) return 'Optimal';
    if (k <= 400) return 'Slightly High';
    return 'Excessive';
  }

  // Convert sensor raw value to percentage (0-1999 -> 0-100%)
  double _sensorToPercentage(double raw, double max) {
    return ((raw / max) * 100).clamp(0, 100);
  }

  // Get user-friendly NPK description showing raw value + status
  String _getNPKDescription(String nutrient, double value, String status) {
    return '$nutrient: ${value.toStringAsFixed(0)} mg/kg — $status';
  }

  // Get EC status
  String _getECStatus(double ec) {
    if (ec < 100) return '(Very Low)';
    if (ec <= 500) return '(Optimal)';
    if (ec <= 800) return '(High)';
    return '(Too High - Salinity Issue)';
  }

  // Get temperature status
  String _getTempStatus(double temp) {
    if (temp < 18) return '(Cool)';
    if (temp <= 25) return '(Optimal)';
    if (temp <= 28) return '(Warm)';
    return '(Too Hot)';
  }

  Map<String, dynamic> _calculateStatistics(List<SoilData> soilDataList) {
    int healthy = 0;
    int alerts = 0;
    for (var data in soilDataList) {
      if (data.soilHealth.toLowerCase().contains('good') ||
          data.soilHealth.toLowerCase().contains('excellent')) {
        healthy++;
      }
      if (data.soilHealth.toLowerCase().contains('poor') ||
          data.soilHealth.toLowerCase().contains('critical')) {
        alerts++;
      }
    }
    return {
      'healthy': healthy,
      'active': soilDataList.length,
      'alerts': alerts,
    };
  }

  // Zone boundaries: 5 zones × 25 blocks × 25 sectors = 625 hectares per zone.
  // North=1-625, East=626-1250, South=1251-1875, West=1876-2500, Central=2501-3125
  String _getZoneNameForHectare(int hectareId) {
    if (hectareId <= 625) return 'North Zone';
    if (hectareId <= 1250) return 'East Zone';
    if (hectareId <= 1875) return 'South Zone';
    if (hectareId <= 2500) return 'West Zone';
    return 'Central Zone';
  }
}

Widget _buildLoadingView() {
  return const Center(child: CircularProgressIndicator());
}

Widget _buildErrorView(String err) {
  return Center(child: Text('Error: $err'));
}

class RadialZonePainter extends CustomPainter {
  final List<PlantationZone> zones;
  final int? selectedZoneId;

  RadialZonePainter({required this.zones, this.selectedZoneId});

  // Each outer segment: [startAngle, sweepAngle] in radians
  // (0 = right/3-o'clock, clockwise)
  static const Map<int, List<double>> _segmentAngles = {
    1: [-3 * math.pi / 4, math.pi / 2], // North: upper arc
    2: [-math.pi / 4, math.pi / 2], // East:  right arc
    3: [math.pi / 4, math.pi / 2], // South: lower arc
    4: [3 * math.pi / 4, math.pi / 2], // West:  left arc
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) * 0.42;
    final innerRadius = outerRadius * 0.30;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // Draw outer ring shadow
    shadowPaint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(center, outerRadius + 4, shadowPaint);

    // ── Draw 4 outer segments ──────────────────────────────────────────────
    for (final entry in _segmentAngles.entries) {
      final zoneId = entry.key;
      final angles = entry.value;
      final isSelected = selectedZoneId == zoneId;

      // Get health color from model
      final zone = zones.firstWhere((z) => z.id == zoneId);
      final baseColor = zone.healthColor;

      // Segment path: outer arc + inner arc (donut slice)
      final path = Path()
        ..addArc(outerRect, angles[0], angles[1])
        ..arcTo(innerRect, angles[0] + angles[1], -angles[1], false)
        ..close();

      // Glow for selected
      if (isSelected) {
        glowPaint.color = baseColor.withOpacity(0.55);
        canvas.drawPath(path, glowPaint);
      }

      // Fill with radial gradient simulation by using opacity
      fillPaint.shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          baseColor.withOpacity(isSelected ? 0.95 : 0.85),
          baseColor.withOpacity(isSelected ? 1.0 : 0.95), // Darker at edge
        ],
      ).createShader(outerRect);

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // ── Draw center inner circle ───────────────────────────────────────────
    final centerZone = zones.firstWhere((z) => z.id == 5);
    final centerColor = centerZone.healthColor;
    final isCenterSelected = selectedZoneId == 5;

    if (isCenterSelected) {
      glowPaint.color = centerColor.withOpacity(0.55);
      canvas.drawCircle(center, innerRadius, glowPaint);
    }

    fillPaint.shader = RadialGradient(
      colors: [
        centerColor.withOpacity(isCenterSelected ? 0.95 : 0.85),
        centerColor.withOpacity(isCenterSelected ? 1.0 : 0.95),
      ],
    ).createShader(innerRect);
    canvas.drawCircle(center, innerRadius, fillPaint);
    canvas.drawCircle(center, innerRadius, borderPaint);

    // ── Draw outer circle border ───────────────────────────────────────────
    canvas.drawCircle(
      center,
      outerRadius,
      borderPaint
        ..color = Colors.white
        ..strokeWidth = 2.5,
    );

    // ── Draw zone labels ───────────────────────────────────────────────────
    final midRadius = (innerRadius + outerRadius) / 2;
    _drawLabel(
      canvas,
      'North',
      center + Offset(0, -midRadius),
      isSelected: selectedZoneId == 1,
    );
    _drawLabel(
      canvas,
      'East',
      center + Offset(midRadius, 0),
      isSelected: selectedZoneId == 2,
    );
    _drawLabel(
      canvas,
      'South',
      center + Offset(0, midRadius),
      isSelected: selectedZoneId == 3,
    );
    _drawLabel(
      canvas,
      'West',
      center + Offset(-midRadius, 0),
      isSelected: selectedZoneId == 4,
    );
    _drawLabel(
      canvas,
      'Central',
      center,
      isSelected: selectedZoneId == 5,
      fontSize: 13,
    );

    // ── Zone sub-count badges ─────────────────────────────────────────────
    const badgeOffset = 18.0;
    _drawBadge(canvas, '25', center + Offset(0, -midRadius + badgeOffset));
    _drawBadge(
      canvas,
      '25',
      center + Offset(midRadius - badgeOffset * 0.5, badgeOffset),
    );
    _drawBadge(canvas, '25', center + Offset(0, midRadius - badgeOffset));
    _drawBadge(
      canvas,
      '25',
      center + Offset(-midRadius + badgeOffset * 0.5, badgeOffset),
    );
    _drawBadge(canvas, '25', center + Offset(0, innerRadius * 0.55));
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position, {
    bool isSelected = false,
    double fontSize = 14,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
          fontSize: isSelected ? fontSize + 1 : fontSize,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBadge(Canvas canvas, String text, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFB9F6CA),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RadialZonePainter oldDelegate) =>
      oldDelegate.selectedZoneId != selectedZoneId ||
      oldDelegate.zones != zones;
}
