import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../models/market_models.dart';

class MarketApiService {
  static const String _baseUrl =
      'https://tea-powder-classification-market-value-api.up.railway.app';

  /// Check API Health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch overall market prices grid
  Future<MarketPriceResponse> getMarketPrices() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/v1/market-price'));

    if (response.statusCode == 200) {
      return MarketPriceResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load market prices: ${response.body}');
    }
  }

  /// Classify image online
  Future<ClassificationResult> classifyImageOnline(File imageFile) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/v1/classify'));
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final result = ClassificationResult.fromJson(json.decode(responseData),
          imageFile: imageFile);

      // Save to DB Microservice (awaited)
      await _saveToDbClassification(result, imageFile.path);

      return result;
    } else {
      throw Exception('Failed to classify image: $responseData');
    }
  }

  /// Calculate market price for a specific grade and inputs
  Future<PricingResponse> calculatePrice(PricingRequest request,
      {String? imagePath}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/price'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final result = PricingResponse.fromJson(json.decode(response.body));

      // Save to DB Microservice (awaited)
      await _saveToDbPricing(request, result, imagePath: imagePath);

      return result;
    } else {
      throw Exception('Failed to calculate price: ${response.body}');
    }
  }

  Future<void> _saveToDbClassification(
      ClassificationResult result, String imagePath) async {
    try {
      String? imageBase64;
      final file = File(imagePath);
      if (await file.exists()) {
        imageBase64 = base64Encode(await file.readAsBytes());
      }

      final body = {
        'image_path': imagePath,
        'image_data': imageBase64,
        'grade': result.grade,
        'confidence': result.confidence,
        'confidence_label': result.confidenceLabel,
        'is_ambiguous': result.isAmbiguous,
        'source': result.source,
      };

      // Determine if this is a powder grade (saved to dbPowder) or other market value (dbMarket)
      final bool isPowderGrade = [
        'BOP',
        'BOPF',
        'Dust',
        'Dust1',
        'Fanning1',
        'Pekoe'
      ].contains(result.grade);
      final String endpoint =
          isPowderGrade ? ApiConfig.dbPowder : ApiConfig.dbMarket;

      final response = await http
          .post(Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Market/Powder classification saved to DB ($endpoint)');
      } else {
        print('⚠️ DB error saving classification: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error saving market classification: $e');
    }
  }

  Future<void> _saveToDbPricing(
      PricingRequest request, PricingResponse response,
      {String? imagePath}) async {
    try {
      String? imageBase64;
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          imageBase64 = base64Encode(await file.readAsBytes());
        }
      }

      final body = {
        'user_id': null,
        'grade': request.grade,
        'confidence': request.confidence,
        'color': request.color,
        'aroma': request.aroma,
        'age': request.age,
        'quantity': request.quantity,
        'price_per_kg': response.pricePerKg,
        'total_price': response.pricePerKg * request.quantity,
        'market_price': (response.inputs['market_price'] as num?)?.toDouble() ??
            response.pricePerKg,
        'currency': 'LKR',
        'status': response.status,
        'is_pricing': true,
        'image_path': imagePath,
        'image_data': imageBase64,
        'extra': null,
      };

      final httpResponse = await http
          .post(Uri.parse(ApiConfig.dbMarket),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        print('✅ Market pricing saved to DB');
      } else {
        print('⚠️ DB error saving pricing: ${httpResponse.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error saving market pricing: $e');
    }
  }

  /// Publish a weekly market price update (Admin)
  Future<void> publishMarketValues(MarketPriceUpdate update) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/market-price'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(update.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to publish market prices: ${response.body}');
    }
  }
}
