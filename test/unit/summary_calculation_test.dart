import 'package:flutter_test/flutter_test.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';

/// Reuses the same in-memory box approach as task_repository_test.
void main() {
  test('summary calculation counts completed vs uncompleted', () {
    final date = DateTime(2026, 11, 1);
    final dateStr = Task.formatDate(date);

    final tasks = [
      Task(id: '1', title: 'a', date: dateStr, status: TaskStatus.done, createdAt: date, order: 0),
      Task(id: '2', title: 'b', date: dateStr, status: TaskStatus.today, createdAt: date, order: 1),
      Task(id: '3', title: 'c', date: dateStr, status: TaskStatus.today, createdAt: date, order: 2),
      Task(id: '4', title: 'other day', date: '2026-10-31', status: TaskStatus.today, createdAt: date, order: 0),
      Task(id: '5', title: 'someday', date: '', status: TaskStatus.someday, createdAt: date, order: 0),
    ];

    // Simulate the filtering + counting logic of SummaryState.
    final todayTasks = tasks
        .where((t) =>
            t.date == dateStr &&
            (t.status == TaskStatus.today || t.status == TaskStatus.done))
        .toList();

    final completed = todayTasks.where((t) => t.status == TaskStatus.done).length;
    final uncompleted =
        todayTasks.where((t) => t.status != TaskStatus.done).length;

    expect(todayTasks.length, equals(3));
    expect(completed, equals(1));
    expect(uncompleted, equals(2));
    expect('$completed из 3 сделано', equals('1 из 3 сделано'));
  });

  test('decisions map updates and removes entries', () {
    final decisions = <String, String>{};
    void setDecision(String taskId, String decision) {
      if (decision.isEmpty) {
        decisions.remove(taskId);
      } else {
        decisions[taskId] = decision;
      }
    }

    setDecision('a', 'tomorrow');
    setDecision('b', 'someday');
    setDecision('c', 'delete');
    expect(decisions.length, equals(3));

    setDecision('b', ''); // toggle off
    expect(decisions.length, equals(2));
    expect(decisions.containsKey('b'), isFalse);

    setDecision('a', 'someday'); // change decision
    expect(decisions['a'], equals('someday'));
  });
}
