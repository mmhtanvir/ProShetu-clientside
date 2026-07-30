import 'package:flutter_test/flutter_test.dart';
import 'package:proshetu/core/utils/result.dart';

void main() {
  test('Result folds correctly', () {
    const Result<String, int> ok = Ok(42);
    const Result<String, int> err = Err('boom');

    expect(ok.fold((f) => -1, (v) => v), 42);
    expect(err.fold((f) => f, (v) => '$v'), 'boom');
    expect(ok.isOk, isTrue);
    expect(err.isOk, isFalse);
  });
}
