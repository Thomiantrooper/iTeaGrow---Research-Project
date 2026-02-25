import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tea_colors.dart';
import '../../../../core/design_system/tea_typography.dart';
import '../../../../core/design_system/tea_spacing.dart';
import '../../../../core/providers/iot_live_provider.dart';
import '../../data/datasources/fertilizer_ml_service.dart';
import '../../domain/entities/fertilizer_recommendation.dart';
import 'package:iteagrow/features/iot_connectivity/domain/models/iot_models.dart';

class SoilFertilizationScreen extends ConsumerStatefulWidget {
  const SoilFertilizationScreen({super.key});

  @override
  ConsumerState<SoilFertilizationScreen> createState() =>
      _SoilFertilizationScreenState();
}

class _SoilFertilizationScreenState extends ConsumerState<SoilFertilizationScreen> {
  final FertilizerMLService _mlService = FertilizerMLService();

  // NPK and pH are not from ESP32 — keep as manual/default values
  double soilPH = 6.2;
  double nitrogen = 42.0;
  double phosphorus = 28.0;
  double potassium = 35.0;

  FertilizerRecommendation? _recommendation;
  bool _isCalculating = false;

  Future<void> _getFertilizerRecommendation() async {
    setState(() => _isCalculating = true);

    try {
      final recommendation = await _mlService.recommend(
        currentNitrogen: nitrogen,
        currentPhosphorus: phosphorus,
        currentPotassium: potassium,
        soilPH: soilPH,
        cropStage: 'vegetative', // This should come from user input or system
      );

      setState(() {
        _recommendation = recommendation;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: TeaColors.alertRust),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(iotLiveProvider);
    final device = liveState.deviceList.isNotEmpty ? liveState.deviceList.first : null;
    final soilMoisture = device?.soilMoisture ?? 65.5;
    final temperature  = device?.temperature  ?? 26.5;
    final humidity     = device?.humidity     ?? 72.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Monitoring & Fertilization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(iotLiveProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: TeaColors.healthyGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TeaColors.healthyGreen.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live Monitoring Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TeaColors.healthyGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Soil Monitoring Section
            Text(
              'Soil Monitoring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Live Sensor Readings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSensorReading(
                      SensorType.soilMoisture,
                      soilMoisture,
                      _getSensorStatus(SensorType.soilMoisture, soilMoisture),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.soilPH,
                      soilPH,
                      _getSensorStatus(SensorType.soilPH, soilPH),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.nitrogen,
                      nitrogen,
                      _getSensorStatus(SensorType.nitrogen, nitrogen),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.phosphorus,
                      phosphorus,
                      _getSensorStatus(SensorType.phosphorus, phosphorus),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.potassium,
                      potassium,
                      _getSensorStatus(SensorType.potassium, potassium),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.temperature,
                      temperature,
                      _getSensorStatus(SensorType.temperature, temperature),
                    ),
                    const Divider(height: 24),
                    _buildSensorReading(
                      SensorType.humidity,
                      humidity,
                      _getSensorStatus(SensorType.humidity, humidity),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Fertilization Section
            Text(
              'Fertilization Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Get Recommendation Button
            ElevatedButton.icon(
              onPressed: _isCalculating ? null : _getFertilizerRecommendation,
              icon: _isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: TeaColors.white,),
                    )
                  : const Icon(Icons.calculate),
              label: Text(_isCalculating
                  ? 'Calculating...'
                  : 'Get TRI-Based Recommendation',),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            // Recommendation Results
            if (_recommendation != null) ...[
              const SizedBox(height: 24),
              _buildRecommendationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorReading(
      SensorType type, double value, SensorStatus status,) {
    final typeColor = _getSensorTypeColor(type);
    final statusColor = _getSensorStatusColor(status);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(type.icon, color: typeColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${value.toStringAsFixed(1)} ${type.unit}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    return Card(
      color: TeaColors.warmAmber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: TeaColors.warmAmber, size: 28),
                SizedBox(width: 12),
                Text(
                  'TRI-Based Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // NPK Recommendations
            _buildNutrientRecommendation(
                'Nitrogen (N)', _recommendation!.nitrogenAmount,),
            const SizedBox(height: 12),
            _buildNutrientRecommendation(
                'Phosphorus (P)', _recommendation!.phosphorusAmount,),
            const SizedBox(height: 12),
            _buildNutrientRecommendation(
                'Potassium (K)', _recommendation!.potassiumAmount,),

            const Divider(height: 24),

            // Reasoning
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: TeaColors.infoSky, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!.reasoning,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Generated at: ${_formatTime(_recommendation!.timestamp)}',
              style: TextStyle(fontSize: 12, color: TeaColors.darkGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRecommendation(String nutrient, double amount) {
    final needsApplication = amount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          nutrient,
          style: const TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            if (needsApplication)
              const Icon(Icons.add_circle, color: TeaColors.warningAmber, size: 20)
            else
              const Icon(Icons.check_circle, color: TeaColors.healthyGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              needsApplication
                  ? '${amount.toStringAsFixed(1)} kg/ha'
                  : 'Sufficient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: needsApplication
                    ? TeaColors.warningAmber
                    : TeaColors.healthyGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  SensorStatus _getSensorStatus(SensorType type, double value) {
    // Simple thresholds - replace with actual TRI guidelines
    switch (type) {
      case SensorType.soilMoisture:
        if (value < 40) return SensorStatus.critical;
        if (value < 50) return SensorStatus.warning;
        if (value > 80) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.soilPH:
        if (value < 5.0 || value > 7.0) return SensorStatus.critical;
        if (value < 5.5 || value > 6.5) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.nitrogen:
        if (value < 30) return SensorStatus.critical;
        if (value < 40) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.phosphorus:
        if (value < 20) return SensorStatus.critical;
        if (value < 30) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.potassium:
        if (value < 20) return SensorStatus.critical;
        if (value < 25) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.temperature:
        if (value < 15 || value > 35) return SensorStatus.critical;
        if (value < 20 || value > 30) return SensorStatus.warning;
        return SensorStatus.optimal;
      case SensorType.humidity:
        if (value < 40 || value > 90) return SensorStatus.critical;
        if (value < 50 || value > 80) return SensorStatus.warning;
        return SensorStatus.optimal;
      default:
        return SensorStatus.normal;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Color _getSensorTypeColor(SensorType type) {
    switch (type) {
      case SensorType.soilMoisture:
        return TeaColors.infoSky;
      case SensorType.soilPH:
        return TeaColors.clayPot;
      case SensorType.nitrogen:
        return TeaColors.healthyGreen;
      case SensorType.phosphorus:
        return TeaColors.warningAmber;
      case SensorType.potassium:
        return TeaColors.alertRust;
      case SensorType.temperature:
        return TeaColors.warmAmber;
      case SensorType.humidity:
        return TeaColors.infoSky;
      default:
        return TeaColors.mediumGray;
    }
  }

  Color _getSensorStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.critical:
        return TeaColors.alertRust;
      case SensorStatus.warning:
        return TeaColors.warningAmber;
      case SensorStatus.normal:
        return TeaColors.infoSky;
      case SensorStatus.optimal:
        return TeaColors.healthyGreen;
      default:
        return TeaColors.mediumGray;
    }
  }
}
