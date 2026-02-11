import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/prediction_request_model.dart';
import '../providers/yield_prediction_provider.dart';
import 'yield_results_screen.dart';

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
  int _laborTotal = 56;
  double _fieldSize = 6.59;
  double _cropHarvested = 1036;
  double _gPct = 39;
  double _cPct = 47;
  double _dPct = 14;
  int _predictionDays = 7;

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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check internet connectivity
    final connectivity = ref.read(connectivityStatusProvider);
    final predictionState = ref.read(yieldPredictionProvider);

    // Allow submission if connected OR if API is healthy (even if google ping failed)
    if (connectivity.value == false && !predictionState.isApiHealthy) {
      _showError('Internet connection required for yield prediction');
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

    await ref.read(yieldPredictionProvider.notifier).getPrediction(request);

    final state = ref.read(yieldPredictionProvider);

    if (state.result != null && state.result!.success) {
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TeaColors.alertRust,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: TeaColors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final predictionState = ref.watch(yieldPredictionProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Yield Prediction'),
        actions: [
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
                  predictionState.isApiHealthy ? 'Online' : 'Offline',
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
                      const Expanded(
                        child: Text(
                          'No internet connection. Please connect to use yield prediction.',
                          style: TextStyle(color: TeaColors.nearBlack),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _checkConnectivityAndHealth,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
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
              decoration: const InputDecoration(
                labelText: 'Division',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: ['LN', 'NC', 'LYN', 'ELT']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => _divisionId = value!),
            ),

            const SizedBox(height: 16),

            // Labor Total
            TextFormField(
              initialValue: _laborTotal.toString(),
              decoration: const InputDecoration(
                labelText: 'Number of Workers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (int.parse(value) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
              onChanged: (value) =>
                  _laborTotal = int.tryParse(value) ?? _laborTotal,
            ),

            const SizedBox(height: 16),

            // Field Size
            TextFormField(
              initialValue: _fieldSize.toString(),
              decoration: const InputDecoration(
                labelText: 'Field Size (hectares)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.landscape),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
              onChanged: (value) =>
                  _fieldSize = double.tryParse(value) ?? _fieldSize,
            ),

            const SizedBox(height: 16),

            // Crop Harvested
            TextFormField(
              initialValue: _cropHarvested.toString(),
              decoration: const InputDecoration(
                labelText: 'Crop Harvested (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grass),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
              onChanged: (value) =>
                  _cropHarvested = double.tryParse(value) ?? _cropHarvested,
            ),

            const SizedBox(height: 24),

            // Grade Percentages Section
            const Text(
              'Tea Grade Percentages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Grade G%
            TextFormField(
              initialValue: _gPct.toString(),
              decoration: const InputDecoration(
                labelText: 'Grade G (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return 'Must be between 0 and 100';
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
              initialValue: _cPct.toString(),
              decoration: const InputDecoration(
                labelText: 'Grade C (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return 'Must be between 0 and 100';
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
              initialValue: _dPct.toString(),
              decoration: const InputDecoration(
                labelText: 'Grade D (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final val = double.parse(value);
                if (val < 0 || val > 100) {
                  return 'Must be between 0 and 100';
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
                  const Text('Total:'),
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
                  'Percentages must sum to 100%',
                  style: TextStyle(color: TeaColors.warningAmber, fontSize: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Prediction Days Slider
            const Text(
              'Prediction Days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  : const Text(
                      'Get Prediction',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
