import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'dart:async';
import '../../../../core/services/connectivity_service.dart';
import '../data/models/market_models.dart';
import '../providers/market_providers.dart';
import 'widgets/market_charts.dart';
import '../../powder_grading/data/datasources/powder_validation_service.dart';

class MarketAnalysisScreen extends ConsumerStatefulWidget {
  const MarketAnalysisScreen({super.key});

  @override
  ConsumerState<MarketAnalysisScreen> createState() =>
      _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends ConsumerState<MarketAnalysisScreen> {
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkConnectivityAndHealth());
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectivityAndHealth();
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivityAndHealth() async {
    ref.read(marketApiHealthProvider.notifier).checkHealth();
    await ref.read(connectivityServiceProvider).checkConnectivity();

    // Automatically re-fetch market prices from the DB on every health check
    ref.invalidate(marketPricesProvider);
  }

  double _colorVal = 0.5;
  double _aromaVal = 0.5;
  double _ageVal = 0.5;
  double _quantity = 500;
  final List<String> _gradesList = [
    'BOPF',
    'BOP',
    'Pekoe',
    'Fanning1',
    'Dust',
    'Dust1'
  ];
  String _selectedGrade = 'BOPF';

  final ImagePicker _picker = ImagePicker();
  final PowderValidationService _powderValidator = PowderValidationService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    // ── Pre-scan powder validation ───────────────────────────────────
    // Checks: min resolution, sharpness, colour variance,
    // green-dominance rejection, brownish powder pixel ratio.
    final bytes = await pickedFile.readAsBytes();
    final validation = await _powderValidator.validate(bytes);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: TeaColors.alertRust,
          ),
        );
      }
      return;
    }

    ref.read(classificationProvider.notifier).classify(File(pickedFile.path));
  }

  void _calculatePrice(ClassificationResult? classification) {
    // If classification is ready, use it. Else fallback to manual _selectedGrade
    final String targetGrade = classification?.grade ?? _selectedGrade;
    final double targetConfidence = classification?.confidence ?? 100.0;

    final request = PricingRequest(
      grade: targetGrade,
      confidence: targetConfidence,
      color: _colorVal,
      aroma: _aromaVal,
      age: _ageVal,
      quantity: _quantity,
    );

    ref.read(priceCalculationProvider.notifier).calculatePrice(request);
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classificationProvider);
    final priceState = ref.watch(priceCalculationProvider);
    final marketGridAsync = ref.watch(marketPricesProvider);
    final isApiHealthy = ref.watch(marketApiHealthProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    final isOnline = connectivityStatus.value == true && isApiHealthy;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: Text(l10n.market_title,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline
                      ? TeaColors.healthyGreen
                      : TeaColors.warningAmber,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? l10n.common_online : l10n.common_offline,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOnline) ...[
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
                          l10n.market_no_internet,
                          style: TextStyle(color: TeaColors.nearBlack),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _checkConnectivityAndHealth,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.common_retry),
                        style: TextButton.styleFrom(
                          foregroundColor: TeaColors.warmAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Classification Section
            _buildImagePickerBox(classState),
            const SizedBox(height: 24),

            // Grade Selection Section (Manual Override)
            Text(l10n.market_select_grade,
                style: TeaTypography.titleLarge),
            const SizedBox(height: 12),
            _buildGradeDropdown(classState.value),
            const SizedBox(height: 24),

            // Inputs Section
            Text(l10n.market_your_quality, style: TeaTypography.titleLarge),
            const SizedBox(height: 12),
            _buildQualitySelectors(),
            const SizedBox(height: 24),

            // Quantity
            _buildQuantitySelector(),
            const SizedBox(height: 32),

            // ── Low-confidence scan advisory ───────────────────────────
            if (classState.value != null &&
                !classState.value!.isValidationFailure &&
                (classState.value!.confidenceLabel == 'Low' ||
                    classState.value!.confidenceLabel == 'Uncertain' ||
                    classState.value!.isAmbiguous))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: TeaColors.warmAmber.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: TeaColors.warmAmber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: TeaColors.warmAmber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.market_scan_confidence_advisory(
                          classState.value!.confidenceLabel.toLowerCase(),
                          classState.value!.grade,
                        ),
                        style: const TextStyle(
                            fontSize: 12, color: TeaColors.warmAmber),
                      ),
                    ),
                  ],
                ),
              ),

            // Predict Button
            ElevatedButton(
              onPressed: priceState.isLoading || !isOnline
                  ? null
                  : () => _calculatePrice(classState.value),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeaColors.freshLeaf,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: priceState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.market_calculate,
                      style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 24),

            // Output Results
            if (priceState.value != null && !priceState.isLoading) ...[
              _buildResultsCard(
                  priceState.value!, classState.value?.grade ?? _selectedGrade),
            ],

            if (priceState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('${l10n.common_error}: ${priceState.error}',
                    style: const TextStyle(color: Colors.red)),
              ),

            // Market Analysis Tools
            if (isOnline) ...[
              const SizedBox(height: 32),
              Text(l10n.market_insights, style: TeaTypography.titleLarge),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: TeaColors.freshLeaf.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: TeaColors.freshLeaf.withOpacity(0.1)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    listTileTheme: ListTileTheme.of(context).copyWith(
                      dense: true,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (priceState.value != null &&
                          !priceState.isLoading) ...[
                        _buildExpansionSection(
                          title: l10n.market_quality_analysis,
                          subtitle: l10n.market_quality_impact,
                          children: _buildQualityAnalysisChildren(),
                        ),
                        Divider(
                            height: 1,
                            color: TeaColors.freshLeaf.withOpacity(0.1)),
                      ],
                      _buildExpansionSection(
                        title: l10n.market_grade_comparison,
                        subtitle: l10n.market_grade_benchmarks,
                        children: [
                          const SizedBox(height: 16),
                          _buildGradeValueChart(marketGridAsync),
                          const SizedBox(height: 16),
                          _buildMarketGrid(marketGridAsync),
                        ],
                      ),
                      Divider(
                          height: 1,
                          color: TeaColors.freshLeaf.withOpacity(0.1)),
                      _buildExpansionSection(
                        title: l10n.market_historical,
                        subtitle: l10n.market_historical_subtitle,
                        children: [
                          const SizedBox(height: 16),
                          _buildMarketTrendSection(marketGridAsync,
                              classState.value?.grade ?? _selectedGrade),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _confidenceLabelColor(String label) {
    switch (label) {
      case 'High':
        return TeaColors.healthyGreen;
      case 'Moderate':
        return TeaColors.warmAmber;
      case 'Low':
        return Colors.orange;
      default:
        return TeaColors.alertRust;
    }
  }

  Widget _buildImagePickerBox(AsyncValue<ClassificationResult?> state) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: TeaColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TeaColors.goldenSunlight, width: 2),
        ),
        child: state.when(
          data: (result) {
            if (result == null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt,
                      size: 64, color: TeaColors.goldenSunlight),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.market_tap_capture,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              );
            }
            // ── Validation failure ─────────────────────────────────────────
            if (result.isValidationFailure) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: TeaColors.alertRust, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.validationMessage ??
                            AppLocalizations.of(context)!.market_image_validation_failed,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                // ── Ambiguity banner ──────────────────────────────────
                if (result.isAmbiguous)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: TeaColors.warmAmber.withOpacity(0.12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: TeaColors.warmAmber, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.powder_borderline,
                            style: const TextStyle(
                                fontSize: 11, color: TeaColors.warmAmber),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      if (result.imageFile != null)
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(22),
                              bottomLeft: Radius.circular(22),
                            ),
                            child: Image.file(
                              result.imageFile!,
                              fit: BoxFit.cover,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.market_detected_grade,
                                  style: const TextStyle(
                                      fontSize: 12, color: TeaColors.darkGray)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: TeaColors.goldenSunlight
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(result.grade,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: TeaColors.nearBlack)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${result.confidence.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  // ── Confidence label badge ───────────
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _confidenceLabelColor(
                                              result.confidenceLabel)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      result.confidenceLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _confidenceLabelColor(
                                            result.confidenceLabel),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: result.confidence / 100,
                                backgroundColor: TeaColors.lightGray,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    TeaColors.healthyGreen),
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: TeaColors.lightGray,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text(
                                      result.source == 'offline'
                                          ? AppLocalizations.of(context)!.market_local_ai
                                          : AppLocalizations.of(context)!.market_cloud_ai,
                                      style: const TextStyle(
                                          color: TeaColors.darkGray,
                                          fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${AppLocalizations.of(context)!.common_error}: $e')),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.market_take_photo),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.common_gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDropdown(ClassificationResult? classResult) {
    // Determine which string to show based on if the user scanned something
    final activeGrade = classResult?.grade ?? _selectedGrade;

    return DropdownButtonFormField<String>(
      value: activeGrade,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.market_tea_grade,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.local_offer_outlined),
        enabled: classResult == null, // Disable if image is uploaded
      ),
      items: _gradesList
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: classResult != null
          ? null
          : (val) {
              if (val != null) {
                setState(() => _selectedGrade = val);
              }
            },
    );
  }

  Widget _buildQualitySelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQualitySelectorRow(
          AppLocalizations.of(context)!.market_color,
          _colorVal,
          (v) => setState(() => _colorVal = v),
          [
            {'label': AppLocalizations.of(context)!.market_premium, 'val': 1.0, 'icon': Icons.star_border},
            {'label': AppLocalizations.of(context)!.market_normal, 'val': 0.5, 'icon': Icons.check_circle_outline},
            {'label': AppLocalizations.of(context)!.market_dull, 'val': 0.0, 'icon': Icons.remove_circle_outline},
          ],
        ),
        const SizedBox(height: 16),
        _buildQualitySelectorRow(
          AppLocalizations.of(context)!.market_aroma,
          _aromaVal,
          (v) => setState(() => _aromaVal = v),
          [
            {'label': AppLocalizations.of(context)!.market_strong, 'val': 1.0, 'icon': Icons.air},
            {
              'label': AppLocalizations.of(context)!.market_moderate,
              'val': 0.5,
              'icon': Icons.water_drop_outlined
            },
            {'label': AppLocalizations.of(context)!.market_weak, 'val': 0.0, 'icon': Icons.eco_outlined},
          ],
        ),
        const SizedBox(height: 16),
        _buildQualitySelectorRow(
          AppLocalizations.of(context)!.market_age,
          _ageVal,
          (v) => setState(() => _ageVal = v),
          [
            {'label': AppLocalizations.of(context)!.market_fresh, 'val': 1.0, 'icon': Icons.grass},
            {
              'label': AppLocalizations.of(context)!.market_medium_age,
              'val': 0.5,
              'icon': Icons.access_time
            },
            {'label': AppLocalizations.of(context)!.market_old, 'val': 0.0, 'icon': Icons.history},
          ],
        ),
      ],
    );
  }

  Widget _buildQualitySelectorRow(String title, double currentVal,
      Function(double) onChanged, List<Map<String, dynamic>> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((opt) {
            final isSelected = currentVal == opt['val'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (opt['icon'] != null) ...[
                    Icon(
                      opt['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : TeaColors.darkGray,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(opt['label'],
                      style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : TeaColors.darkGray,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
              selected: isSelected,
              onSelected: (b) {
                if (b) onChanged(opt['val']);
              },
              selectedColor: TeaColors.freshLeaf,
              backgroundColor: Colors.white,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isSelected
                          ? TeaColors.freshLeaf
                          : TeaColors.mediumGray.withOpacity(0.5))),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.market_quantity,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [100, 250, 500, 1000, 2500, 5000].map((qty) {
            final isSelected = _quantity == qty.toDouble();
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : TeaColors.darkGray,
                  ),
                  const SizedBox(width: 6),
                  Text('$qty kg',
                      style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : TeaColors.darkGray,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _quantity = qty.toDouble());
              },
              selectedColor: TeaColors.freshLeaf,
              backgroundColor: Colors.white,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isSelected
                          ? TeaColors.freshLeaf
                          : TeaColors.mediumGray.withOpacity(0.5))),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _quantity,
          min: 100,
          max: 5000,
          divisions: 49,
          label: '${_quantity.toInt()} kg',
          activeColor: TeaColors.freshLeaf,
          onChanged: (value) {
            setState(() => _quantity = value);
          },
        ),
        Center(
          child: Text(
            '${_quantity.toInt()} kg',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard(PricingResponse response, String grade) {
    final total = response.pricePerKg * _quantity;
    // Sanity check: realistic Sri Lankan tea price range Rs. 200–4,000/kg
    final bool priceOutOfRange =
        response.pricePerKg < 200 || response.pricePerKg > 4000;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.market_prediction_result,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Rs. ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: TeaColors.freshLeaf),
            ),
            Text(
              'Rs. ${response.pricePerKg.toStringAsFixed(2)} per kg • $grade',
              style: const TextStyle(fontSize: 14),
            ),
            // ── Price sanity advisory ─────────────────────────────────
            if (priceOutOfRange)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: TeaColors.alertRust.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: TeaColors.alertRust.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: TeaColors.alertRust, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Price per kg (Rs. ${response.pricePerKg.toStringAsFixed(0)}) '
                          'is outside the expected range (Rs. 200–4,000/kg). '
                          'Please verify your inputs.',
                          style: const TextStyle(
                              fontSize: 11, color: TeaColors.alertRust),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 32),
            _buildResRow('Base Price (Live)',
                'Rs. ${(response.inputs['market_price'] ?? 0).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildResRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMarketGrid(AsyncValue<MarketPriceResponse> asyncData) {
    return asyncData.when(
      data: (res) {
        if (res.marketPrices.isEmpty)
          return Text(AppLocalizations.of(context)!.market_no_data);
        // Get the most recent week, correctly ignoring 'default'
        final latestPrices = res.latestPrices;

        final gradesList = [
          'BOPF',
          'BOP',
          'Pekoe',
          'Fanning1',
          'Dust',
          'Dust1'
        ];
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: gradesList.map((g) {
            final price = latestPrices[g] != null
                ? 'Rs. ${latestPrices[g].toStringAsFixed(2)}'
                : '---';
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        g,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TeaColors.freshLeaf),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        price,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('${AppLocalizations.of(context)!.market_error_loading}: $e'),
    );
  }

  List<Widget> _buildQualityAnalysisChildren() {
    final insight = _getManagerInsight();
    return [
      const SizedBox(height: 16),
      const RadarChartLegend(),
      const SizedBox(height: 24),
      QualityRadarChart(
        color: _colorVal,
        aroma: _aromaVal,
        age: _ageVal,
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: TeaColors.freshLeaf.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TeaColors.freshLeaf.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: TeaColors.freshLeaf),
                const SizedBox(width: 8),
                Text("Manager's Insight",
                    style: TeaTypography.titleSmall.copyWith(
                        color: TeaColors.freshLeaf,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight,
              style: const TextStyle(
                  fontSize: 14, color: TeaColors.nearBlack, height: 1.4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  String _getManagerInsight() {
    final l10n = AppLocalizations.of(context)!;
    if (_colorVal >= 0.8 && _aromaVal >= 0.8 && _ageVal >= 0.8) {
      return l10n.market_insight_excellent;
    }
    if (_colorVal <= _aromaVal && _colorVal <= _ageVal) {
      return l10n.market_insight_color_low;
    } else if (_aromaVal <= _colorVal && _aromaVal <= _ageVal) {
      return l10n.market_insight_aroma_low;
    } else {
      return l10n.market_insight_freshness_low;
    }
  }

  Widget _buildGradeValueChart(AsyncValue<MarketPriceResponse> asyncData) {
    return asyncData.when(
      data: (res) => GradeValueChart(
        latestPrices: res.latestPrices,
        grades: _gradesList,
      ),
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('${AppLocalizations.of(context)!.common_error}: $e'),
    );
  }

  Widget _buildMarketTrendSection(
      AsyncValue<MarketPriceResponse> asyncData, String selectedGrade) {
    return asyncData.when(
      data: (res) => MarketTrendChart(
        res: res,
        selectedGrade: selectedGrade,
      ),
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('${AppLocalizations.of(context)!.common_error}: $e'),
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      title: Text(title, style: TeaTypography.titleLarge),
      subtitle: Text(subtitle, style: TeaTypography.labelSmall),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }
}
