import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_config.dart';
import '../models/market_models.dart';

class MarketApiService {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'api_access_token';
  static const String _baseUrl =
      'https://tea-powder-classification-market-value-api.up.railway.app';

  MarketApiService(this._prefs);

  /// Decode user_id from the stored JWT token without verifying signature.
  String? _getUserIdFromToken() {
    final token = _prefs.getString(_tokenKey);
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      // JWT payload is base64url-encoded - pad to multiple of 4
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      return map['user_id']?.toString() ?? map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = _prefs.getString(_tokenKey);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/price'),
      headers: headers,
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final result = PricingResponse.fromJson(json.decode(response.body));

      // Save to DB Microservice (awaited)
      final recordId =
          await _saveToDbPricing(request, result, imagePath: imagePath);

      return result.copyWith(id: recordId);
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

      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(endpoint), headers: headers, body: jsonEncode(body))
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

  Future<String?> _saveToDbPricing(
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
        'user_id': _getUserIdFromToken(),
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

      final headers = await _getHeaders();
      final httpResponse = await http
          .post(Uri.parse(ApiConfig.dbMarket),
              headers: headers,
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        final respBody = jsonDecode(httpResponse.body);
        print('✅ Market pricing saved to DB');
        return respBody['id']?.toString();
      } else {
        print('⚠️ DB error saving pricing: ${httpResponse.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error saving market pricing: $e');
    }
    return null;
  }

  /// Publish a weekly market price update (Admin)
  Future<void> publishMarketValues(MarketPriceUpdate update) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/market-price'),
      headers: headers,
      body: json.encode(update.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to publish market prices: ${response.body}');
    }
  }

  /// Get user's market pricing history
  Future<List<Map<String, dynamic>>> getMarketHistory() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(ApiConfig.marketHistory),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load market history: ${response.body}');
    }
  }

  /// Get full report data for a market record
  Future<Map<String, dynamic>> getMarketReportData(String recordId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(ApiConfig.marketReportData(recordId)),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load market report data: ${response.body}');
    }
  }

  /// Get summarized market pricing data for analytics
  Future<Map<String, dynamic>> getMarketSummary({int days = 30}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.dbMicroserviceBaseUrl}/api/reports/market-summary?days=$days'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load market summary: ${response.body}');
    }
  }
}
