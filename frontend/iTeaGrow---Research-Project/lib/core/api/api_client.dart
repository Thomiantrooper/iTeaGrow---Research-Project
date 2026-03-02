import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Determine MIME type from file extension (defaults to image/jpeg)
MediaType _imageMimeType(String path) {
  final ext = path.toLowerCase().split('.').last;
  switch (ext) {
    case 'png': return MediaType('image', 'png');
    case 'webp': return MediaType('image', 'webp');
    case 'bmp': return MediaType('image', 'bmp');
    case 'gif': return MediaType('image', 'gif');
    default: return MediaType('image', 'jpeg'); // jpg / jpeg / unknown
  }
}

/// HTTP client for communicating with the backend API
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  /// Check if the backend server is reachable
  Future<bool> isServerReachable() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.health))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {...ApiConfig.defaultHeaders, ...?headers},
          )
          .timeout(const Duration(seconds: ApiConfig.receiveTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// POST request with JSON body
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              ...ApiConfig.defaultHeaders,
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConfig.receiveTimeout));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// POST request with multipart form data (for image upload)
  Future<Map<String, dynamic>> postMultipart(
    String url, {
    required File imageFile,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({...ApiConfig.defaultHeaders, ...?headers});

      // Add image file with explicit content type so backend doesn't get octet-stream
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: _imageMimeType(imageFile.path),
      ),);

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: ApiConfig.receiveTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// POST request with multipart form data from file path
  Future<Map<String, dynamic>> postMultipartFromPath(
    String url, {
    required String imagePath,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({...ApiConfig.defaultHeaders, ...?headers});

      // Add image file from path with explicit content type so backend doesn't get octet-stream
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: _imageMimeType(imagePath),
      ),);

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: ApiConfig.receiveTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// POST request with multiple files from paths (for batch processing)
  Future<Map<String, dynamic>> postMultipleFilesFromPaths(
    String url, {
    required List<String> imagePaths,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({...ApiConfig.defaultHeaders, ...?headers});

      // Add all image files
      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          imagePaths[i],
        ),);
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: ApiConfig.batchTimeout),
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return {};
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Invalid response format');
      }
    } else if (statusCode == 400) {
      final error = _parseError(body);
      throw BadRequestException(error);
    } else if (statusCode == 401) {
      throw UnauthorizedException('Unauthorized access');
    } else if (statusCode == 404) {
      throw NotFoundException('Resource not found');
    } else if (statusCode == 422) {
      final error = _parseError(body);
      throw ValidationException(error);
    } else if (statusCode >= 500) {
      throw ServerException('Server error: $statusCode');
    } else {
      throw ApiException('HTTP error: $statusCode');
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        return json['message'] ?? json['detail'] ?? json['error'] ?? body;
      }
      return body;
    } catch (e) {
      return body;
    }
  }

  void dispose() {
    _client.close();
  }
}
