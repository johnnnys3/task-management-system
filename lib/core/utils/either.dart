import 'package:task_management/core/errors/failures.dart';

/// Either type for handling success or failure scenarios
/// Left represents Failure, Right represents Success
abstract class Either<L, R> {
  const Either();
  
  /// Creates a Left value (Failure)
  factory Either.left(L value) = Left<L, R>;
  
  /// Creates a Right value (Success)
  factory Either.right(R value) = Right<L, R>;
  
  /// Pattern matching for Either
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);
  
  /// Checks if this is Left
  bool isLeft();
  
  /// Checks if this is Right
  bool isRight();
  
  /// Gets the Left value if present, null otherwise
  L? getLeft();
  
  /// Gets the Right value if present, null otherwise
  R? getRight();
}

/// Left side of Either (represents Failure)
class Left<L, R> extends Either<L, R> {
  
  const Left(this.value);
  final L value;
  
  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onLeft(value);
  }
  
  @override
  bool isLeft() => true;
  
  @override
  bool isRight() => false;
  
  @override
  L? getLeft() => value;
  
  @override
  R? getRight() => null;
}

/// Right side of Either (represents Success)
class Right<L, R> extends Either<L, R> {
  
  const Right(this.value);
  final R value;
  
  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onRight(value);
  }
  
  @override
  bool isLeft() => false;
  
  @override
  bool isRight() => true;
  
  @override
  L? getLeft() => null;
  
  @override
  R? getRight() => value;
}

/// Type alias for common Either usage with Failure
typedef Result<T> = Either<Failure, T>;
