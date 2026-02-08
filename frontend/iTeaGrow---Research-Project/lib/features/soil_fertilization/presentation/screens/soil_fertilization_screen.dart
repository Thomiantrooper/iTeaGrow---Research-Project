import 'package:flutter/material.dart';
import 'package:iteagrow/core/theme/app_theme.dart';
import '../../data/datasources/fertilizer_ml_service.dart';
import '../../domain/entities/fertilizer_recommendation.dart';
import 'package:iteagrow/features/iot_connectivity/domain/models/iot_models.dart';

class SoilFertilizationScreen extends StatefulWidget {
  const SoilFertilizationScreen({super.key});

  @override
  State<SoilFertilizationScreen> createState() =>
      _SoilFertilizationScreenState();
}

class _SoilFertilizationScreenState extends State<SoilFertilizationScreen> {
  final FertilizerMLService _mlService = FertilizerMLService();

  // Live sensor readings (simulated - replace with real IoT data)
  double soilMoisture = 65.5;
  double soilPH = 6.2;
  double nitrogen = 42.0;
  double phosphorus = 28.0;
  double potassium = 35.0;
  double temperature = 26.5;
  double humidity = 72.0;

  FertilizerRecommendation? _recommendation;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // Simulate live data updates
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    // Simulate sensor data updates every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          // Simulate small variations in readings
          soilMoisture += (DateTime.now().millisecond % 10 - 5) * 0.1;
          temperature += (DateTime.now().millisecond % 10 - 5) * 0.05;
          humidity += (DateTime.now().millisecond % 10 - 5) * 0.1;
        });
        _startLiveUpdates();
      }
    });
  }

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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Monitoring & Fertilization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Simulate refresh
                soilMoisture = 60 + (DateTime.now().millisecond % 20);
                soilPH = 5.5 + (DateTime.now().millisecond % 15) * 0.1;
              });
            },
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
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
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
                    color: Colors.green,
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
                          strokeWidth: 2, color: Colors.white,),
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
      color: AppTheme.accentAmber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: AppTheme.accentAmber, size: 28),
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
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              const Icon(Icons.add_circle, color: AppTheme.statusWarning, size: 20)
            else
              const Icon(Icons.check_circle, color: AppTheme.statusGood, size: 20),
            const SizedBox(width: 8),
            Text(
              needsApplication
                  ? '${amount.toStringAsFixed(1)} kg/ha'
                  : 'Sufficient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: needsApplication
                    ? AppTheme.statusWarning
                    : AppTheme.statusGood,
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
        return Colors.blue;
      case SensorType.soilPH:
        return Colors.purple;
      case SensorType.nitrogen:
        return Colors.green;
      case SensorType.phosphorus:
        return Colors.orange;
      case SensorType.potassium:
        return Colors.red;
      case SensorType.temperature:
        return Colors.deepOrange;
      case SensorType.humidity:
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  Color _getSensorStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.critical:
        return AppTheme.statusCritical;
      case SensorStatus.warning:
        return AppTheme.statusWarning;
      case SensorStatus.normal:
        return Colors.blue;
      case SensorStatus.optimal:
        return AppTheme.statusGood;
      default:
        return Colors.grey;
    }
  }
}
