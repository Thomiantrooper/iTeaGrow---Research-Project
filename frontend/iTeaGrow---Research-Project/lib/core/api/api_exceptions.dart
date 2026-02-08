/// Base API exception class
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Bad request (400) exception
class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

/// Unauthorized (401) exception
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

/// Not found (404) exception
class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

/// Validation (422) exception
class ValidationException extends ApiException {
  ValidationException(super.message);
}

/// Server (5xx) exception
class ServerException extends ApiException {
  ServerException(super.message);
}

/// Network/Connection exception
class NetworkException extends ApiException {
  NetworkException(super.message);
}
