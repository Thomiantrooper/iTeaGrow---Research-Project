import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'dart:async';
import '../../../../core/services/connectivity_service.dart';
import '../data/models/market_models.dart';
import '../providers/market_providers.dart';

class MarketValueAdminScreen extends ConsumerStatefulWidget {
  const MarketValueAdminScreen({super.key});

  @override
  ConsumerState<MarketValueAdminScreen> createState() =>
      _MarketValueAdminScreenState();
}

class _MarketValueAdminScreenState
    extends ConsumerState<MarketValueAdminScreen> {
  Timer? _connectivityTimer;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _placeholders = {};
  final List<String> _gradesList = [
    'BOPF',
    'BOP',
    'Pekoe',
    'Fanning1',
    'Dust',
    'Dust1'
  ];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final String _defaultNotes =
      "BOPF appreciated by Rs.20-40/kg. Active buying.";
  final String _defaultSource = "Tea Auction";
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var g in _gradesList) {
      _controllers[g] = TextEditingController();
      _placeholders[g] = "1000.0";
    }
    _dateController.text = _getCurrentAuctionWeek();

    Future.microtask(() => _checkConnectivityAndHealth());
    _connectivityTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _checkConnectivityAndHealth());
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    for (var c in _controllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    _sourceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _populateFromLatest(MarketPriceResponse res) {
    final latestPrices = res.latestPrices;
    if (latestPrices.isEmpty) return;

    for (var g in _gradesList) {
      if (latestPrices[g] != null) {
        _placeholders[g] = (latestPrices[g] as num).toStringAsFixed(2);
      }
    }
    if (res.lastNotes != null) _placeholders['notes'] = res.lastNotes!;
    if (res.lastSource != null) _placeholders['source'] = res.lastSource!;
  }

  String _getCurrentAuctionWeek() {
    final now = DateTime.now();
    // In Dart, weekday is 1 for Monday, 7 for Sunday.
    // Subtract (weekday - 1) days to reliably snap to the preceding Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
  }

  Future<void> _savePrices() async {
    final api = ref.read(marketApiServiceProvider);

    final parsedPrices = <String, double>{}; // Renamed prices to parsedPrices
    for (var g in _gradesList) {
      final text = _controllers[g]!.text;
      parsedPrices[g] = text.isEmpty
          ? double.tryParse(_placeholders[g] ?? "0.0") ?? 0.0
          : double.tryParse(text) ?? 0.0;
    }

    final update = MarketPriceUpdate(
      auctionWeek: _dateController.text,
      prices: parsedPrices,
      notes: _notesController.text,
      source: _sourceController.text.isEmpty
          ? 'Manager Update'
          : _sourceController.text,
    );

    try {
      await api.publishMarketValues(update);
      if (mounted) {
        // ── IMPORTANT: Immediate Refresh ────────────────────────────────────────
        // We await the refresh to ensure the next build gets the latest data
        await ref.refresh(marketPricesProvider.future);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.market_published),
              backgroundColor: Colors.green));

          // Clear local UI state/text to show fresh database values/placeholders
          setState(() {
            for (var c in _controllers.values) {
              c.clear();
            }
            _notesController.clear();
            _sourceController.clear();
            // Reset placeholders to trigger a fresh population in build()
            _placeholders.clear();
            for (var g in _gradesList) {
              _placeholders[g] = "1000.0";
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${AppLocalizations.of(context)!.common_error}: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _checkConnectivityAndHealth() async {
    ref.read(marketApiHealthProvider.notifier).checkHealth();
    await ref.read(connectivityServiceProvider).checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    final marketGridAsync = ref.watch(marketPricesProvider);
    final isApiHealthy = ref.watch(marketApiHealthProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOnline = connectivityStatus.value == true && isApiHealthy;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.market_admin_title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final res = ref.read(marketPricesProvider).value;
              if (res != null) {
                context.push('/market-admin/report', extra: res);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.white : TeaColors.warningAmber,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline
                      ? AppLocalizations.of(context)!.common_online
                      : AppLocalizations.of(context)!.common_offline,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: marketGridAsync.when(
        data: (res) {
          if (res.marketPrices.isNotEmpty) {
            // Schedule populated state to avoid build interference
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_placeholders['BOPF'] == "1000.0" ||
                  _placeholders['notes'] == null) {
                setState(() => _populateFromLatest(res));
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(marketPricesProvider.future),
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Ensure it's always scrollable for refresh
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppLocalizations.of(context)!.market_weekly_prices,
                      style: TeaTypography.headlineMedium),
                  const SizedBox(height: 16),
                  _buildPriceGrid(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isOnline ? _savePrices : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeaColors.freshLeaf,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                        AppLocalizations.of(context)!.market_save_publish,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      isOnline
                          ? AppLocalizations.of(context)!.market_connected
                          : AppLocalizations.of(context)!.market_disconnected,
                      style: TextStyle(
                        color: isOnline
                            ? TeaColors.healthyGreen
                            : TeaColors.warningAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildHistorySection(res),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(
                '${AppLocalizations.of(context)!.market_load_failed}: $e')),
      ),
    );
  }

  Widget _buildPriceGrid() {
    return Column(
      children: _gradesList.map((g) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TeaColors.mediumGray),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(g,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: TeaColors.freshLeaf)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _controllers[g],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      prefixText: 'Rs. ',
                      hintText: _placeholders[g],
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TeaColors.mistGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.market_source,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _sourceController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: _placeholders['source'] ?? _defaultSource,
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.market_auction_notes,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _placeholders['notes'] ?? _defaultNotes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(MarketPriceResponse res) {
    // Sort chronologically (most recent first)
    final keys = res.marketPrices.keys.where((k) => k != 'default').toList()
      ..sort((a, b) => b.compareTo(a));

    if (keys.isEmpty) return const SizedBox.shrink(); // No history yet

    // We no longer skip(1) - show all records including the latest one
    final historyKeys = keys;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(AppLocalizations.of(context)!.market_prev_auctions,
            style: TeaTypography.titleLarge),
        tilePadding: EdgeInsets.zero,
        children: historyKeys.map((week) {
          final prices = res.marketPrices[week] ?? {};
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.date_range,
                              color: TeaColors.freshLeaf, size: 18),
                          const SizedBox(width: 8),
                          Text(
                              '${AppLocalizations.of(context)!.market_week_of}: $week',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      // ── Edit Button (Restriction: 24h & Latest Only) ───────────
                      if (week == keys.first && res.canEditLatest)
                        IconButton(
                          icon: const Icon(Icons.edit_note,
                              color: TeaColors.freshLeaf),
                          tooltip: 'Edit this week\'s prices',
                          onPressed: () {
                            setState(() {
                              _dateController.text = week;
                              for (var g in _gradesList) {
                                if (prices[g] != null) {
                                  _controllers[g]!.text =
                                      (prices[g] as num).toStringAsFixed(2);
                                }
                              }
                              if (res.lastNotes != null)
                                _notesController.text = res.lastNotes!;
                              if (res.lastSource != null)
                                _sourceController.text = res.lastSource!;
                            });
                            // Scroll to top
                            PrimaryScrollController.of(context).animateTo(0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 12),
                  LayoutBuilder(builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: _gradesList.map((g) {
                        final val = prices.containsKey(g)
                            ? (prices[g] as num).toDouble()
                            : 0.0;
                        return SizedBox(
                          width: itemWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(g,
                                  style: const TextStyle(
                                      color: TeaColors.darkGray, fontSize: 13)),
                              Text('Rs. ${val.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  })
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
