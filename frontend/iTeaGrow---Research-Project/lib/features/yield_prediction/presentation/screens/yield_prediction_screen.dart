import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/prediction_request_model.dart';
import '../providers/yield_prediction_provider.dart';
import 'yield_results_screen.dart';
import 'yield_history_screen.dart';

class YieldPredictionScreen extends ConsumerStatefulWidget {
  const YieldPredictionScreen({super.key});

  @override
  ConsumerState<YieldPredictionScreen> createState() =>
      _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  Timer? _connectivityTimer; // Timer for auto-refresh

  // Form fields
  String _divisionId = 'LN';
  int _laborTotal = 0;
  double _fieldSize = 0;
  double _cropHarvested = 0;
  double _gPct = 0;
  double _cPct = 0;
  double _dPct = 0;
  int _predictionDays = 1;

  @override
  void initState() {
    super.initState();
    // Check API health on load
    Future.microtask(() {
      _checkConnectivityAndHealth();
    });

    // Auto-refresh connectivity every 3 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkConnectivityAndHealth();
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndHealth() async {
    ref.read(yieldPredictionProvider.notifier).checkHealth();
    await ref.read(connectivityServiceProvider).checkConnectivity();
  }

  double get _totalPercentage => _gPct + _cPct + _dPct;

  // ── Cross-field consistency checks ────────────────────────────────────────
  // Realistic Sri Lankan estate ranges:
  //   crop-per-ha : 100 – 5 000 kg/ha
  //   workers-per-ha: 5 – 80  workers/ha
  String? get _cropPerHaWarning {
    if (_fieldSize <= 0 || _cropHarvested <= 0) return null;
    final ratio = _cropHarvested / _fieldSize;
    if (ratio < 50) {
      return 'Crop/ha (${ratio.toStringAsFixed(0)} kg/ha) is unusually low — verify inputs.';
    }
    if (ratio > 10000) {
      return 'Crop/ha (${ratio.toStringAsFixed(0)} kg/ha) is unusually high — verify inputs.';
    }
    return null;
  }

  String? get _workersPerHaWarning {
    if (_fieldSize <= 0 || _laborTotal <= 0) return null;
    final ratio = _laborTotal / _fieldSize;
    if (ratio < 2) {
      return 'Workers/ha (${ratio.toStringAsFixed(1)}) seems low for the field size.';
    }
    if (ratio > 150) {
      return 'Workers/ha (${ratio.toStringAsFixed(1)}) seems high for the field size.';
    }
    return null;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check internet connectivity
    final connectivity = ref.read(connectivityStatusProvider);
    final predictionState = ref.read(yieldPredictionProvider);

    // Allow submission if connected OR if API is healthy (even if google ping failed)
    if (connectivity.value == false && !predictionState.isApiHealthy) {
      _showError(AppLocalizations.of(context)!.yield_internet_required);
      return;
    }

    final request = PredictionRequestModel(
      divisionId: _divisionId,
      laborTotal: _laborTotal,
      fieldSizeHa: _fieldSize,
      cropHarvestedKg: _cropHarvested,
      gPct: _gPct,
      cPct: _cPct,
      dPct: _dPct,
      predictionDays: _predictionDays,
    );

    // Show confirmation dialog before proceeding
    final confirmed = await _showConfirmationDialog(request);
    if (!confirmed) return;

    await ref.read(yieldPredictionProvider.notifier).getPrediction(request);

    final state = ref.read(yieldPredictionProvider);

    if (state.result != null && state.result!.success) {
      unawaited(_saveToDb(request, state.result!));
      // Navigate to results
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YieldResultsScreen(
              result: state.result!,
              predictionRequest: request,
            ),
          ),
        );
      }
    } else if (state.error != null) {
      _showError(state.error!);
    }
  }

  Future<bool> _showConfirmationDialog(PredictionRequestModel request) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.assignment_turned_in,
                    color: TeaColors.freshLeaf),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.yield_confirm_title,
                      style: TeaTypography.titleMedium),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.yield_confirm_msg,
                      style: const TextStyle(color: TeaColors.darkGray)),
                  const SizedBox(height: 16),
                  _buildConfirmItem(l10n.yield_division, request.divisionId),
                  _buildConfirmItem(
                      l10n.yield_workers, request.laborTotal.toString()),
                  _buildConfirmItem(
                      l10n.yield_field_size, '${request.fieldSizeHa} ha'),
                  _buildConfirmItem(
                      l10n.yield_crop, '${request.cropHarvestedKg} kg'),
                  _buildConfirmItem(
                      l10n.yield_prediction_days, '${request.predictionDays}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel,
                    style: const TextStyle(color: TeaColors.mediumGray)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeaColors.freshLeaf,
                  foregroundColor: TeaColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.yield_confirm_proceed),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: TeaColors.darkGray),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: TeaColors.freshLeaf),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDb(
      PredictionRequestModel req, dynamic result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer token';
      await http.post(
        Uri.parse(ApiConfig.dbYield),
        headers: headers,
        body: jsonEncode({
          'division_id': req.divisionId,
          'labor_total': req.laborTotal,
          'field_size_ha': req.fieldSizeHa,
          'crop_harvested_kg': req.cropHarvestedKg,
          'g_pct': req.gPct,
          'c_pct': req.cPct,
          'd_pct': req.dPct,
          'prediction_days': req.predictionDays,
          'total_predicted_yield_kg': result.summary.totalPredictedYield,
          'average_daily_yield_kg': result.summary.averageDailyYield,
          'days_predicted': result.summary.daysPredicted,
        }),
      );
    } catch (e) {
      debugPrint('Yield save error: e');
    }
  }

  Widget _buildConsistencyWarning(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TeaColors.warningAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TeaColors.warningAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: TeaColors.warningAmber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(fontSize: 12, color: TeaColors.warningAmber),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TeaColors.alertRust,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.alert_dismiss,
          textColor: TeaColors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final predictionState = ref.watch(yieldPredictionProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.yield_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const YieldHistoryScreen()),
            ),
          ),
          // API Health Indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  predictionState.isApiHealthy
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: predictionState.isApiHealthy
                      ? TeaColors.healthyGreen
                      : TeaColors.warningAmber,
                ),
                const SizedBox(width: 4),
                Text(
                  predictionState.isApiHealthy
                      ? AppLocalizations.of(context)!.common_online
                      : AppLocalizations.of(context)!.common_offline,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Internet Status Warning with Refresh Button
            // Only show if both connectivity check fails AND API health check fails
            if (connectivityStatus.value == false &&
                !predictionState.isApiHealthy)
              Card(
                color: TeaColors.warningAmber.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: TeaColors.warningAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.yield_no_internet,
                          style: const TextStyle(color: TeaColors.nearBlack),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _checkConnectivityAndHealth,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(AppLocalizations.of(context)!.common_retry),
                        style: TextButton.styleFrom(
                          foregroundColor: TeaColors.warmAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Division Selection
            DropdownButtonFormField<String>(
              value: _divisionId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_division,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
              items: ['LN', 'NC', 'LYN', 'ELT']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => _divisionId = value!),
            ),

            const SizedBox(height: 16),

            // Labor Total
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_workers,
                hintText: AppLocalizations.of(context)!.yield_workers_hint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return AppLocalizations.of(context)!.yield_valid_number;
                }
                final v = int.parse(value);
                if (v <= 0)
                  return AppLocalizations.of(context)!.yield_greater_than_zero;
                if (v > 5000) return 'Maximum 5000 workers';
                return null;
              },
              onChanged: (value) {
                setState(
                    () => _laborTotal = int.tryParse(value) ?? _laborTotal);
              },
            ),

            const SizedBox(height: 16),

            // Field Size
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_field_size,
                hintText: AppLocalizations.of(context)!.yield_field_hint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.landscape),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return AppLocalizations.of(context)!.yield_valid_number;
                }
                final v = double.parse(value);
                if (v <= 0)
                  return AppLocalizations.of(context)!.yield_greater_than_zero;
                if (v > 5000) return 'Maximum 5,000 ha';
                return null;
              },
              onChanged: (value) {
                setState(
                    () => _fieldSize = double.tryParse(value) ?? _fieldSize);
              },
            ),

            const SizedBox(height: 16),

            // Crop Harvested
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_crop,
                hintText: AppLocalizations.of(context)!.yield_crop_hint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.grass),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return AppLocalizations.of(context)!.yield_valid_number;
                }
                final v = double.parse(value);
                if (v <= 0)
                  return AppLocalizations.of(context)!.yield_greater_than_zero;
                if (v > 500000) return l10n.yield_max_crop;
                return null;
              },
              onChanged: (value) {
                setState(() =>
                    _cropHarvested = double.tryParse(value) ?? _cropHarvested);
              },
            ),

            // ── Cross-field consistency warnings ──────────────────────────────
            if (_cropPerHaWarning != null || _workersPerHaWarning != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    if (_cropPerHaWarning != null)
                      _buildConsistencyWarning(_cropPerHaWarning!),
                    if (_workersPerHaWarning != null)
                      _buildConsistencyWarning(_workersPerHaWarning!),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Grade Percentages Section
            Text(
              AppLocalizations.of(context)!.yield_grade_percentages,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Grade G%
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_grade_g,
                hintText: 'e.g. 39',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return l10n.yield_valid_number;
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return l10n.yield_pct_range;
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _gPct = double.tryParse(value) ?? _gPct);
              },
            ),

            const SizedBox(height: 12),

            // Grade C%
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_grade_c,
                hintText: 'e.g. 47',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return l10n.yield_valid_number;
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return l10n.yield_pct_range;
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _cPct = double.tryParse(value) ?? _cPct);
              },
            ),

            const SizedBox(height: 12),

            // Grade D%
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yield_grade_d,
                hintText: 'e.g. 14',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return l10n.yield_valid_number;
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return l10n.yield_pct_range;
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _dPct = double.tryParse(value) ?? _dPct);
              },
            ),

            const SizedBox(height: 8),

            // Percentage Total Indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_totalPercentage - 100).abs() < 0.1
                    ? TeaColors.leafPale
                    : TeaColors.warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_totalPercentage - 100).abs() < 0.1
                      ? TeaColors.healthyGreen
                      : TeaColors.warningAmber,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.yield_total),
                  Text(
                    '${_totalPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (_totalPercentage - 100).abs() < 0.1
                          ? TeaColors.healthyGreen
                          : TeaColors.warningAmber,
                    ),
                  ),
                ],
              ),
            ),

            if ((_totalPercentage - 100).abs() > 0.1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.yield_pct_warning,
                  style: TextStyle(color: TeaColors.warningAmber, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Prediction Days Slider
            Text(
              AppLocalizations.of(context)!.yield_prediction_days,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _predictionDays.toDouble(),
              min: 1,
              max: 14,
              divisions: 13,
              label: '$_predictionDays days',
              onChanged: (value) {
                setState(() => _predictionDays = value.toInt());
              },
            ),
            Text(
              '$_predictionDays days',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: predictionState.isLoading ||
                      (connectivityStatus.value == false &&
                          !predictionState.isApiHealthy) ||
                      (_totalPercentage - 100).abs() > 0.1
                  ? null
                  : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: predictionState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TeaColors.white,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.yield_get_prediction,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
