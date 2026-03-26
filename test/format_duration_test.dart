import 'package:flow_app/shared/format_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('zero seconds', () {
      expect(formatDuration(0), '0m 0s');
    });

    test('seconds only', () {
      expect(formatDuration(45), '0m 45s');
    });

    test('minutes and seconds', () {
      expect(formatDuration(125), '2m 5s');
    });

    test('exact minutes', () {
      expect(formatDuration(300), '5m 0s');
    });

    test('hours minutes seconds', () {
      expect(formatDuration(3661), '1h 1m 1s');
    });

    test('hours and minutes no seconds', () {
      expect(formatDuration(3600), '1h 0m 0s');
    });

    test('large duration', () {
      expect(formatDuration(7384), '2h 3m 4s');
    });
  });
}
