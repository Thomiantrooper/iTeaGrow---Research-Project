/// Request model for Tea Yield Prediction API
class PredictionRequestModel {
  final String divisionId;
  final int laborTotal;
  final double fieldSizeHa;
  final double cropHarvestedKg;
  final double gPct;
  final double cPct;
  final double dPct;
  final int predictionDays;

  PredictionRequestModel({
    required this.divisionId,
    required this.laborTotal,
    required this.fieldSizeHa,
    required this.cropHarvestedKg,
    required this.gPct,
    required this.cPct,
    required this.dPct,
    this.predictionDays = 1,
  });

  /// Validate request data
  bool isValid() {
    // Check percentages sum to 100
    double total = gPct + cPct + dPct;
    if ((total - 100).abs() > 0.1) return false;

    // Check valid division
    if (!['LN', 'NC', 'LYN', 'ELT'].contains(divisionId)) return false;

    // Check positive values
    if (laborTotal <= 0 || fieldSizeHa <= 0 || cropHarvestedKg <= 0) {
      return false;
    }

    // Check prediction days range
    if (predictionDays < 1 || predictionDays > 14) return false;

    return true;
  }

  /// Get validation error message
  String? getValidationError() {
    double total = gPct + cPct + dPct;
    if ((total - 100).abs() > 0.1) {
      return 'Grade percentages must sum to 100% (current: ${total.toStringAsFixed(1)}%)';
    }

    if (!['LN', 'NC', 'LYN', 'ELT'].contains(divisionId)) {
      return 'Invalid division ID. Must be LN, NC, LYN, or ELT';
    }

    if (laborTotal <= 0) return 'Number of workers must be positive';
    if (fieldSizeHa <= 0) return 'Field size must be positive';
    if (cropHarvestedKg <= 0) return 'Crop harvested must be positive';

    if (predictionDays < 1 || predictionDays > 14) {
      return 'Prediction days must be between 1 and 14';
    }

    return null;
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'division_id': divisionId,
      'labor_total': laborTotal,
      'field_size_ha': fieldSizeHa,
      'crop_harvested_kg': cropHarvestedKg,
      'g_pct': gPct,
      'c_pct': cPct,
      'd_pct': dPct,
      'prediction_days': predictionDays,
    };
  }

  PredictionRequestModel copyWith({
    String? divisionId,
    int? laborTotal,
    double? fieldSizeHa,
    double? cropHarvestedKg,
    double? gPct,
    double? cPct,
    double? dPct,
    int? predictionDays,
  }) {
    return PredictionRequestModel(
      divisionId: divisionId ?? this.divisionId,
      laborTotal: laborTotal ?? this.laborTotal,
      fieldSizeHa: fieldSizeHa ?? this.fieldSizeHa,
      cropHarvestedKg: cropHarvestedKg ?? this.cropHarvestedKg,
      gPct: gPct ?? this.gPct,
      cPct: cPct ?? this.cPct,
      dPct: dPct ?? this.dPct,
      predictionDays: predictionDays ?? this.predictionDays,
    );
  }
}
