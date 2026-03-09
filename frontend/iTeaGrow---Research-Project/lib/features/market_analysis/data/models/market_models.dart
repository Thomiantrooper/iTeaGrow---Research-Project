import 'dart:io';

class PricingRequest {
  final String grade;
  final double confidence;
  final double color;
  final double aroma;
  final double age;
  final double quantity;

  PricingRequest({
    required this.grade,
    required this.confidence,
    required this.color,
    required this.aroma,
    required this.age,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'confidence': confidence,
      'color': color,
      'aroma': aroma,
      'age': age,
      'quantity': quantity,
    };
  }
}

class PricingResponse {
  final double pricePerKg;
  final Map<String, dynamic> inputs;
  final String status;

  PricingResponse({
    required this.pricePerKg,
    required this.inputs,
    required this.status,
  });

  factory PricingResponse.fromJson(Map<String, dynamic> json) {
    return PricingResponse(
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0.0,
      inputs: (json['inputs'] as Map<String, dynamic>?) ?? {},
      status: json['status']?.toString() ?? 'success',
    );
  }
}

class MarketPriceUpdate {
  final String auctionWeek;
  final Map<String, double> prices;
  final String notes;
  final String source;

  MarketPriceUpdate({
    required this.auctionWeek,
    required this.prices,
    required this.notes,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'auction_week': auctionWeek,
      'prices': prices,
      'notes': notes,
      'source': source,
    };
  }
}

class MarketPriceResponse {
  final Map<String, Map<String, dynamic>> marketPrices;
  final String status;
  final String? error;

  MarketPriceResponse({
    required this.marketPrices,
    required this.status,
    this.error,
  });

  Map<String, dynamic> get latestPrices {
    final keys = marketPrices.keys.where((k) => k != 'default').toList()
      ..sort((a, b) => b.compareTo(a));
    if (keys.isNotEmpty) {
      return marketPrices[keys.first]!;
    }
    return marketPrices['default'] ?? {};
  }

  factory MarketPriceResponse.fromJson(Map<String, dynamic> json) {
    // The API might return { "market_price": 1234 } for a specific grade
    // OR { "market_prices": { "2023-10-10": { "BOPF": 1200 } } } for the full grid
    if (json.containsKey('market_prices')) {
      final pricesMap = json['market_prices'] as Map<String, dynamic>;
      final parsedPrices = <String, Map<String, dynamic>>{};

      pricesMap.forEach((key, value) {
        if (value is Map) {
          parsedPrices[key] = Map<String, dynamic>.from(value);
        }
      });

      return MarketPriceResponse(
        marketPrices: parsedPrices,
        status: json['status']?.toString() ?? 'success',
      );
    }

    return MarketPriceResponse(
      marketPrices: {},
      status: json['status']?.toString() ?? 'error',
      error: json['error']?.toString(),
    );
  }
}

class ClassificationResult {
  final String grade;
  final double confidence;
  final String source; // 'online' or 'offline'
  final File? imageFile;

  /// True when a pre-flight or model-level validation check failed.
  final bool isValidationFailure;

  /// Human-readable reason for the validation failure (if [isValidationFailure]).
  final String? validationMessage;

  /// Confidence band: 'High' ≥0.85 / 'Moderate' ≥0.70 / 'Low' ≥0.55 / 'Uncertain'.
  final String confidenceLabel;

  /// True when the top-1 and top-2 class probabilities are within the
  /// ambiguity threshold — the model is not strongly confident.
  final bool isAmbiguous;

  ClassificationResult({
    required this.grade,
    required this.confidence,
    required this.source,
    this.imageFile,
    this.isValidationFailure = false,
    this.validationMessage,
    this.confidenceLabel = 'High',
    this.isAmbiguous = false,
  });

  factory ClassificationResult.fromJson(Map<String, dynamic> json,
      {File? imageFile}) {
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final String labelFromConf;
    if (confidence >= 85.0) {
      labelFromConf = 'High';
    } else if (confidence >= 70.0) {
      labelFromConf = 'Moderate';
    } else if (confidence >= 55.0) {
      labelFromConf = 'Low';
    } else {
      labelFromConf = 'Uncertain';
    }
    return ClassificationResult(
      grade: json['grade']?.toString() ?? 'Unknown',
      confidence: confidence,
      source: 'online',
      imageFile: imageFile,
      confidenceLabel: labelFromConf,
    );
  }
}
