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
  final testDate = DateTime(2026, 11, 1);

  setUp(() {
    box = MemoryTaskBox();
    repository = TaskRepository(box);
  });

  group('TaskRepository - Business Rules', () {
    test('Allows adding up to 3 tasks for today', () async {
      await repository.addTaskToToday(title: 'Task 1', date: testDate);
      await repository.addTaskToToday(title: 'Task 2', date: testDate);
      await repository.addTaskToToday(title: 'Task 3', date: testDate);

      final todayTasks = repository.getTodayTasks(testDate);
      expect(todayTasks.length, equals(3));
      expect(todayTasks.map((t) => t.title), containsAll(['Task 1', 'Task 2', 'Task 3']));
    });

    test('Throws LimitExceededException when attempting to add 4th task to today', () async {
      await repository.addTaskToToday(title: 'Task 1', date: testDate);
      await repository.addTaskToToday(title: 'Task 2', date: testDate);
      await repository.addTaskToToday(title: 'Task 3', date: testDate);

      expect(
        () async => await repository.addTaskToToday(title: 'Task 4', date: testDate),
        throwsA(isA<LimitExceededException>()),
      );
    });

    test('Toggling task done status changes status between today and done', () async {
      final task = await repository.addTaskToToday(title: 'Task 1', date: testDate);
      expect(task.status, equals(TaskStatus.today));

      final doneTask = await repository.toggleTaskDone(task.id);
      expect(doneTask.status, equals(TaskStatus.done));

      final undoneTask = await repository.toggleTaskDone(task.id);
      expect(undoneTask.status, equals(TaskStatus.today));
    });

    test('Moving task to Someday frees a slot on Today', () async {
      final t1 = await repository.addTaskToToday(title: 'Task 1', date: testDate);
      await repository.addTaskToToday(title: 'Task 2', date: testDate);
      await repository.addTaskToToday(title: 'Task 3', date: testDate);

      expect(repository.getTodayTasks(testDate).length, equals(3));

      await repository.moveTaskToSomeday(t1.id);

      expect(repository.getTodayTasks(testDate).length, equals(2));
      expect(repository.getSomedayTasks().length, equals(1));

      // Now adding a 4th overall task to today should succeed because limit is 3
      final t4 = await repository.addTaskToToday(title: 'Task 4', date: testDate);
      expect(t4.title, equals('Task 4'));
      expect(repository.getTodayTasks(testDate).length, equals(3));
    });

    test('Replacing a today task demotes old task to someday and creates new task', () async {
      final t1 = await repository.addTaskToToday(title: 'Task 1', date: testDate);
      await repository.addTaskToToday(title: 'Task 2', date: testDate);
      await repository.addTaskToToday(title: 'Task 3', date: testDate);

      final newTask = await repository.replaceTodayTask(
        oldTaskId: t1.id,
        newTitle: 'Replaced Task 1',
        date: testDate,
      );

      final todayTasks = repository.getTodayTasks(testDate);
      expect(todayTasks.length, equals(3));
      expect(todayTasks.map((t) => t.id), contains(newTask.id));
      expect(todayTasks.map((t) => t.id), isNot(contains(t1.id)));

      final somedayTasks = repository.getSomedayTasks();
      expect(somedayTasks.length, equals(1));
      expect(somedayTasks.first.id, equals(t1.id));
    });

    test('Promoting someday task when today is full replaces selected task', () async {
      final t1 = await repository.addTaskToToday(title: 'Task 1', date: testDate);
      await repository.addTaskToToday(title: 'Task 2', date: testDate);
      await repository.addTaskToToday(title: 'Task 3', date: testDate);
      final s1 = await repository.addTaskToSomeday(title: 'Someday Task');

      await repository.promoteSomedayToTodayReplace(
        somedayTaskId: s1.id,
        replaceOldTaskId: t1.id,
        date: testDate,
      );

      final todayTasks = repository.getTodayTasks(testDate);
      expect(todayTasks.length, equals(3));
      expect(todayTasks.map((t) => t.id), contains(s1.id));
      expect(todayTasks.map((t) => t.id), isNot(contains(t1.id)));

      final somedayTasks = repository.getSomedayTasks();
      expect(somedayTasks.map((t) => t.id), contains(t1.id));
    });

    test('processSummaryDecisions processes tomorrow, someday, and delete correctly', () async {
      final t1 = await repository.addTaskToToday(title: 'Task 1', date: testDate);
      final t2 = await repository.addTaskToToday(title: 'Task 2', date: testDate);
      final t3 = await repository.addTaskToToday(title: 'Task 3', date: testDate);

      final tomorrowDate = testDate.add(const Duration(days: 1));

      await repository.processSummaryDecisions(
        currentDate: testDate,
        decisions: {
          t1.id: 'tomorrow',
          t2.id: 'someday',
          t3.id: 'delete',
        },
      );

      final todayRemaining = repository.getTodayTasks(testDate);
      expect(todayRemaining, isEmpty);

      final tomorrowTasks = repository.getTodayTasks(tomorrowDate);
      expect(tomorrowTasks.length, equals(1));
      expect(tomorrowTasks.first.id, equals(t1.id));

      final somedayTasks = repository.getSomedayTasks();
      expect(somedayTasks.length, equals(1));
      expect(somedayTasks.first.id, equals(t2.id));

      expect(box.get(t3.id), isNull);
    });
  });
}
