import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  
  const Failure(this.message, {this.code = 'unknown'});
  final String message;
  final String code;
  
  @override
  List<Object> get props => [message, code];
  
  @override
  String toString() => 'Failure: $message';
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(String message, {String code = 'server_error'}) 
      : super(message, code: code);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String code = 'network_error'}) 
      : super(message, code: code);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(String message, {String code = 'cache_error'}) 
      : super(message, code: code);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String code = 'validation_error'}) 
      : super(message, code: code);
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message, {String code = 'auth_error'}) 
      : super(message, code: code);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {String code = 'permission_error'}) 
      : super(message, code: code);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(String message, {String code = 'unknown_error'}) 
      : super(message, code: code);
}
