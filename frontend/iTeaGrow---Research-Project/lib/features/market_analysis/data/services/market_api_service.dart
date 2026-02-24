import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
      return ClassificationResult.fromJson(json.decode(responseData),
          imageFile: imageFile);
    } else {
      throw Exception('Failed to classify image: $responseData');
    }
  }

  /// Calculate market price for a specific grade and inputs
  Future<PricingResponse> calculatePrice(PricingRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/price'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return PricingResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to calculate price: ${response.body}');
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
