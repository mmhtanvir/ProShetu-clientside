import '../error/failure.dart';
import '../utils/result.dart';

typedef FutureResult<T> = Future<Result<Failure, T>>;
typedef JsonMap = Map<String, dynamic>;
typedef VoidCallbackAsync = Future<void> Function();
