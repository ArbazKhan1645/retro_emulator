/// Sealed failure classes for error handling across the app
sealed class Failure {
  final String message;
  final String? code;
  final dynamic data;

  const Failure(this.message, {this.code, this.data});

  @override
  String toString() => 'Failure($code): $message';
}

/// Network-related failures
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.data});
}

/// Storage / IO failures
final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code, super.data});
}

/// ROM parsing / scanning failures
final class RomFailure extends Failure {
  const RomFailure(super.message, {super.code, super.data});
}

/// Emulator core failures
final class EmulatorFailure extends Failure {
  const EmulatorFailure(super.message, {super.code, super.data});
}

/// Metadata API failures
final class MetadataFailure extends Failure {
  const MetadataFailure(super.message, {super.code, super.data});
}

/// Authentication failures (RetroAchievements)
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.data});
}

/// Generic unknown failures
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.data});
}
