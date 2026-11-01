import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';
import 'package:one_thing/data/repositories/task_repository.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';

class MemoryTaskBox implements Box<Task> {
  final Map<dynamic, Task> _data = {};

  @override
  Iterable<Task> get values => _data.values;

  @override
  Task? get(dynamic key, {Task? defaultValue}) => _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Task value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }

  @override
  bool get isOpen => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemoryTaskBox box;
  late TaskRepository repository;
  final today = DateTime(2026, 11, 1);
  final tomorrow = DateTime(2026, 11, 2);

  setUp(() {
    box = MemoryTaskBox();
    repository = TaskRepository(box);
  });

  group('Task transfer: tomorrow / someday', () {
    test('processSummaryDecisions moves task to tomorrow date', () async {
      final t1 = await repository.addTaskToToday(title: 'Осталась', date: today);

      await repository.processSummaryDecisions(
        currentDate: today,
        decisions: {t1.id: 'tomorrow'},
      );

      expect(repository.getTodayTasks(today), isEmpty);

      final tomorrowTasks = repository.getTodayTasks(tomorrow);
      expect(tomorrowTasks.length, equals(1));
      expect(tomorrowTasks.first.id, equals(t1.id));
      expect(tomorrowTasks.first.status, equals(TaskStatus.today));
    });

    test('moveTaskToSomeday clears date and sets status', () async {
      final t1 = await repository.addTaskToToday(title: 'Отложить', date: today);

      final moved = await repository.moveTaskToSomeday(t1.id);

      expect(moved.status, equals(TaskStatus.someday));
      expect(moved.date, equals(''));
      expect(repository.getSomedayTasks().length, equals(1));
      expect(repository.getTodayTasks(today), isEmpty);
    });

    test('processSummaryDecisions with someday removes from today and appears in someday', () async {
      final t1 = await repository.addTaskToToday(title: 'Идея', date: today);

      await repository.processSummaryDecisions(
        currentDate: today,
        decisions: {t1.id: 'someday'},
      );

      expect(repository.getTodayTasks(today), isEmpty);
      expect(repository.getSomedayTasks().length, equals(1));
      expect(repository.getSomedayTasks().first.id, equals(t1.id));
    });

    test('moveTaskToToday rejects when target date already full', () async {
      await repository.addTaskToToday(title: '1', date: today);
      await repository.addTaskToToday(title: '2', date: today);
      await repository.addTaskToToday(title: '3', date: today);
      final somedayTask = await repository.addTaskToSomeday(title: '4-я');

      // Tomorrow is empty — the transfer succeeds.
      final moved = await repository.moveTaskToToday(
        taskId: somedayTask.id,
        date: tomorrow,
      );
      expect(moved.status, equals(TaskStatus.today));

      // Filling tomorrow up to 3 and trying a 4th → exception.
      await repository.addTaskToToday(title: 't2', date: tomorrow);
      await repository.addTaskToToday(title: 't3', date: tomorrow);
      final another = await repository.addTaskToSomeday(title: 'Лишняя');

      expect(
        () async => repository.moveTaskToToday(
          taskId: another.id,
          date: tomorrow,
        ),
        throwsA(isA<LimitExceededException>()),
      );
    });

    test('toggleTaskDone keeps the task on the same date', () async {
      final t1 = await repository.addTaskToToday(title: 'Сделать', date: today);

      final done = await repository.toggleTaskDone(t1.id);
      expect(done.status, equals(TaskStatus.done));
      expect(done.date, equals(Task.formatDate(today)));

      // Completed task still occupies one of the 3 slots.
      expect(repository.getTodayTasks(today).length, equals(1));
    });

    test('deleteTask removes the task completely', () async {
      final t1 = await repository.addTaskToToday(title: 'Удалить', date: today);

      await repository.deleteTask(t1.id);

      expect(repository.getTodayTasks(today), isEmpty);
      expect(box.get(t1.id), isNull);
    });
  });
}
