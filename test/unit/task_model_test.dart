import 'package:flutter_test/flutter_test.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';

void main() {
  group('Task model', () {
    test('formatDate produces YYYY-MM-DD with zero padding', () {
      expect(Task.formatDate(DateTime(2026, 1, 5)), equals('2026-01-05'));
      expect(Task.formatDate(DateTime(2026, 11, 23)), equals('2026-11-23'));
    });

    test('copyWith changes only provided fields', () {
      final task = Task(
        id: 'id1',
        title: 'Original',
        date: '2026-11-01',
        status: TaskStatus.today,
        createdAt: DateTime(2026, 11, 1),
        order: 0,
      );

      final copied = task.copyWith(status: TaskStatus.done);

      expect(copied.id, equals('id1'));
      expect(copied.title, equals('Original'));
      expect(copied.status, equals(TaskStatus.done));
      expect(task.status, equals(TaskStatus.today)); // immutable original
    });

    test('equality respects all fields', () {
      final created = DateTime(2026, 11, 1);
      final a = Task(
          id: '1', title: 'A', date: '2026-11-01', status: TaskStatus.today, createdAt: created, order: 0);
      final b = Task(
          id: '1', title: 'A', date: '2026-11-01', status: TaskStatus.today, createdAt: created, order: 0);
      final c = Task(
          id: '1', title: 'A', date: '2026-11-01', status: TaskStatus.done, createdAt: created, order: 0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
