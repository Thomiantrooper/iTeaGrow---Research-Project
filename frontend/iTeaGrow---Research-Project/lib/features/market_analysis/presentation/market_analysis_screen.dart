import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'dart:async';
import '../../../../core/services/connectivity_service.dart';
import '../data/models/market_models.dart';
import '../providers/market_providers.dart';
import 'widgets/market_charts.dart';

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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      ref.read(classificationProvider.notifier).classify(File(pickedFile.path));
    }
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

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        title: const Text('Tea Price Predictor'),
        backgroundColor: TeaColors.freshLeaf,
        foregroundColor: Colors.white,
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
                  isOnline ? 'Online' : 'Offline',
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
                      const Expanded(
                        child: Text(
                          'No internet connection. Please connect internet.',
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
            ],

            // Classification Section
            _buildImagePickerBox(classState),
            const SizedBox(height: 24),

            // Grade Selection Section (Manual Override)
            Text('Or Select Tea Grade Manually',
                style: TeaTypography.titleLarge),
            const SizedBox(height: 12),
            _buildGradeDropdown(classState.value),
            const SizedBox(height: 24),

            // Inputs Section
            Text('Your Tea Quality', style: TeaTypography.titleLarge),
            const SizedBox(height: 12),
            _buildQualitySelectors(),
            const SizedBox(height: 24),

            // Quantity
            _buildQuantitySelector(),
            const SizedBox(height: 32),

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
                  : const Text('Calculate Market Price',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
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
                child: Text('Error: ${priceState.error}',
                    style: const TextStyle(color: Colors.red)),
              ),

            // Market Analysis Tools
            if (isOnline) ...[
              const SizedBox(height: 32),
              Text('Market Insights', style: TeaTypography.titleLarge),
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
                          title: 'My Quality Analysis',
                          subtitle: 'Impact of your tea attributes on price',
                          children: _buildQualityAnalysisChildren(),
                        ),
                        Divider(
                            height: 1,
                            color: TeaColors.freshLeaf.withOpacity(0.1)),
                      ],
                      _buildExpansionSection(
                        title: 'Grade Value Comparison',
                        subtitle: 'Current Rs./kg benchmarks',
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
                        title: 'Historical Market Trends',
                        subtitle: 'Past 3-6 months performance',
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
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt,
                      size: 64, color: TeaColors.goldenSunlight),
                  SizedBox(height: 12),
                  Text('Tap to Capture / Upload Tea Powder',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              );
            }
            return Row(
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
                        const Text('Detected Grade',
                            style: TextStyle(
                                fontSize: 12, color: TeaColors.darkGray)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TeaColors.goldenSunlight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(result.grade,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: TeaColors.nearBlack)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Confidence',
                            style: TextStyle(
                                fontSize: 12, color: TeaColors.darkGray)),
                        const SizedBox(height: 4),
                        Text('${result.confidence.toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
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
                                    ? 'Local AI'
                                    : 'Cloud AI',
                                style: const TextStyle(
                                    color: TeaColors.darkGray, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
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
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
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
        labelText: 'Tea Grade',
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
          'Color',
          _colorVal,
          (v) => setState(() => _colorVal = v),
          [
            {'label': 'Premium', 'val': 1.0, 'icon': Icons.star_border},
            {'label': 'Normal', 'val': 0.5, 'icon': Icons.check_circle_outline},
            {'label': 'Dull', 'val': 0.0, 'icon': Icons.remove_circle_outline},
          ],
        ),
        const SizedBox(height: 16),
        _buildQualitySelectorRow(
          'Aroma',
          _aromaVal,
          (v) => setState(() => _aromaVal = v),
          [
            {'label': 'Strong', 'val': 1.0, 'icon': Icons.air},
            {
              'label': 'Moderate',
              'val': 0.5,
              'icon': Icons.water_drop_outlined
            },
            {'label': 'Weak', 'val': 0.0, 'icon': Icons.eco_outlined},
          ],
        ),
        const SizedBox(height: 16),
        _buildQualitySelectorRow(
          'Age',
          _ageVal,
          (v) => setState(() => _ageVal = v),
          [
            {'label': 'Fresh (<7 days)', 'val': 1.0, 'icon': Icons.grass},
            {
              'label': 'Medium (7-21 days)',
              'val': 0.5,
              'icon': Icons.access_time
            },
            {'label': 'Old (>21 days)', 'val': 0.0, 'icon': Icons.history},
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
        const Text(
          'Quantity (kg)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Prediction Result',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
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
          return const Text('No market data available');
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
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
                    Text(g,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TeaColors.freshLeaf)),
                    Text(price,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading markets: $e'),
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
    if (_colorVal >= 0.8 && _aromaVal >= 0.8 && _ageVal >= 0.8) {
      return "Excellent quality! Your tea meets all premium benchmarks. This will likely fetch the highest market price.";
    }

    // Find lowest score
    if (_colorVal <= _aromaVal && _colorVal <= _ageVal) {
      return "Your tea color is below premium levels. Consider checking your drying temperature and processing speed to avoid dullness.";
    } else if (_aromaVal <= _colorVal && _aromaVal <= _ageVal) {
      return "The aroma profile is weak. This often happens due to over-fermentation. Monitor your fermentation duration more closely.";
    } else {
      return "Freshness is the main issue. Old tea powder loses its 'bite' and market value. Process and pack your batches faster.";
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
      error: (e, _) => Text('Error: $e'),
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
      error: (e, _) => Text('Error: $e'),
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
