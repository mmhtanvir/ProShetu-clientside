import 'package:equatable/equatable.dart';

/// Domain-level failure. Infrastructure exceptions are mapped into
/// one of these before crossing into the domain/presentation layers.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.cause});

  /// Developer-facing description (log-safe; UI uses localized strings).
  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network unavailable', super.cause});
}

final class StorageFailure extends Failure {
  const StorageFailure({super.message = 'Storage error', super.cause});
}

final class CryptoFailure extends Failure {
  const CryptoFailure({super.message = 'Cryptographic error', super.cause});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied', super.cause});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Unexpected error', super.cause});
}
