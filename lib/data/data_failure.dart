/// One error strategy for the whole data layer.
///
/// Everything a repository can fail with is a [DataFailure]. Nothing else
/// escapes: no raw exceptions, no `e.toString()` reaching a screen. A UI can
/// exhaustively switch on this type and know it has handled every case, and a
/// Firestore error code can never leak a stack trace or an internal detail into
/// a price screen.
///
/// The rule this enforces: **a failure a user can see must be phrased as
/// something they can act on.** "Exception: PlatformException" is not. "You're
/// offline — showing saved products" is.
library;

/// A failure that crossed the data boundary.
sealed class DataFailure {
  const DataFailure(this.message);

  /// User-facing copy. Already honest about what is and isn't known.
  final String message;

  /// Whether retrying the same call could plausibly succeed.
  bool get isRetryable => true;

  /// Whether cached content may still be shown alongside this failure. A read
  /// failure with a usable cache is an `OfflineFailure`, not a blank screen.
  bool get keepsCachedContent => false;

  @override
  String toString() => '$runtimeType($message)';
}

/// No usable connection. Cached content, if any, is still worth showing.
final class OfflineFailure extends DataFailure {
  const OfflineFailure([
    super.message = "You're offline. Showing saved products where available.",
  ]);

  @override
  bool get keepsCachedContent => true;
}

/// The backend was reachable but failed. Usually transient.
final class UnreachableFailure extends DataFailure {
  const UnreachableFailure([
    super.message = "Could not reach the catalog. Try again shortly.",
  ]);
}

/// The caller must sign in first.
final class NotAuthenticatedFailure extends DataFailure {
  const NotAuthenticatedFailure([super.message = 'Sign in to continue.']);

  @override
  bool get isRetryable => false;
}

/// Signed in, but not allowed to do this.
final class PermissionDeniedFailure extends DataFailure {
  const PermissionDeniedFailure([
    super.message = "Your account doesn't have access to this.",
  ]);

  @override
  bool get isRetryable => false;
}

/// A response did not match the expected shape — see [ParseFailure].
///
/// Data crossing into this app from outside (a Firestore document, a cached
/// blob) is untrusted. It is validated at the boundary and a malformed record
/// becomes this rather than a crash three layers up.
final class MalformedDataFailure extends DataFailure {
  const MalformedDataFailure(super.message, {this.detail});

  /// Which field failed. Developer-facing; safe to log, never shown raw.
  final String? detail;

  @override
  bool get isRetryable => false;
}

/// A record failed to parse. Carries the field that was wrong.
final class ParseFailure extends MalformedDataFailure {
  ParseFailure(this.field, String reason)
    : super('Saved data could not be read.', detail: '$field: $reason');

  /// The field that failed validation. Developer-facing.
  final String field;
}

/// The build genuinely cannot do this yet.
///
/// This is a product statement, not a stub: the prototype ships with no auth
/// backend, and saying so honestly is better than pretending. Never use it to
/// park work that should be finished.
final class UnsupportedOperationFailure extends DataFailure {
  const UnsupportedOperationFailure(super.message);

  @override
  bool get isRetryable => false;
}

/// A bug. Reached this through a code path that should have been impossible.
final class UnexpectedFailure extends DataFailure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

/// Normalises anything thrown inside a repository into a [DataFailure].
///
/// The mapping is deliberately lossy: an implementation that throws a raw
/// exception should still not reach a screen with an unhandled type, but it
/// should not also pretend to know *why*.
DataFailure asDataFailure(Object error) => switch (error) {
  DataFailure() => error,
  _ => const UnexpectedFailure(),
};
