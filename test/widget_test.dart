import 'package:flutter_test/flutter_test.dart';
import 'package:one_thing/data/models/task.dart';

void main() {
  test('smoke: placeholder replaced by real widget tests later', () {
    expect(Task.formatDate(DateTime(2026, 11, 2)), equals('2026-11-02'));
  });
}
