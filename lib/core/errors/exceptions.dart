/// Base exception for all app-specific exceptions
abstract class AppException implements Exception {
  
  const AppException(this.message, {this.code = 'unknown', this.originalError});
  final String message;
  final String code;
  final dynamic originalError;
  
  @override
  String toString() => 'AppException: $message';
}

/// Server exceptions
class ServerException extends AppException {
  const ServerException(String message, {String code = 'server_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException(String message, {String code = 'network_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(String message, {String code = 'cache_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(String message, {String code = 'validation_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(String message, {String code = 'auth_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(String message, {String code = 'permission_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Parsing exceptions
class ParseException extends AppException {
  const ParseException(String message, {String code = 'parse_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// Unknown/Unexpected exceptions
class UnknownException extends AppException {
  const UnknownException(String message, {String code = 'unknown_error', dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
