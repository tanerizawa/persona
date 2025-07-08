abstract class AppException implements Exception {
  final String message;
  
  AppException(this.message);
  
  @override
  String toString() => message;
}

class ServerException extends AppException {
  ServerException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class RateLimitException extends AppException {
  RateLimitException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

class BiometricException extends AppException {
  BiometricException(super.message);
}

class ApiKeyException extends AppException {
  ApiKeyException(super.message);
}

class LocalDatabaseException extends AppException {
  LocalDatabaseException(super.message);
}

class SynchronizationException extends AppException {
  SynchronizationException(super.message);
}

// Legacy exceptions for compatibility
class AppExceptions implements Exception {
  final String message;
  final String prefix;

  AppExceptions(this.message, this.prefix);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class FetchDataException extends AppExceptions {
  FetchDataException([String? message])
      : super(message ?? "Error During Communication", "Error During Communication: ");
}

class BadRequestException extends AppExceptions {
  BadRequestException([String? message])
      : super(message ?? "Invalid Request", "Invalid Request: ");
}

class UnauthorisedException extends AppExceptions {
  UnauthorisedException([String? message])
      : super(message ?? "Unauthorised", "Unauthorised: ");
}

class InvalidInputException extends AppExceptions {
  InvalidInputException([String? message])
      : super(message ?? "Invalid Input", "Invalid Input: ");
}

class TimeoutException extends AppExceptions {
  TimeoutException([String? message])
      : super(message ?? "Request Timeout", "Request Timeout: ");
}
