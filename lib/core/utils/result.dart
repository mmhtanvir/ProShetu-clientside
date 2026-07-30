/// Minimal Either-style result type — avoids a dependency for one concept.
sealed class Result<L, R> {
  const Result();

  T fold<T>(T Function(L failure) onFailure, T Function(R value) onSuccess) =>
      switch (this) {
        Err<L, R>(:final value) => onFailure(value),
        Ok<L, R>(:final value) => onSuccess(value),
      };

  bool get isOk => this is Ok<L, R>;
}

final class Ok<L, R> extends Result<L, R> {
  const Ok(this.value);
  final R value;
}

final class Err<L, R> extends Result<L, R> {
  const Err(this.value);
  final L value;
}
