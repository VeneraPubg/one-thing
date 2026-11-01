import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'task_repository_interface.dart';

class TaskRepository implements TaskRepositoryInterface {
  final Box<Task> _taskBox;
  final Uuid _uuid;

  static const maxTodayTasks = 3;

  TaskRepository(this._taskBox, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  @override
  List<Task> getTodayTasks(DateTime date) {
    final dateStr = Task.formatDate(date);
    final tasks = _taskBox.values.where((task) {
      return task.date == dateStr &&
          (task.status == TaskStatus.today || task.status == TaskStatus.done);
    }).toList();

    tasks.sort((a, b) {
      final orderCmp = a.order.compareTo(b.order);
      if (orderCmp != 0) return orderCmp;
      return a.createdAt.compareTo(b.createdAt);
    });

    return tasks;
  }

  @override
  List<Task> getActiveTodayTasks(DateTime date) {
    return getTodayTasks(date);
  }

  @override
  List<Task> getSomedayTasks() {
    final tasks = _taskBox.values
        .where((task) => task.status == TaskStatus.someday)
        .toList();

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  @override
  Future<Task> addTaskToToday({
    required String title,
    required DateTime date,
  }) async {
    final currentToday = getTodayTasks(date);
    if (currentToday.length >= maxTodayTasks) {
      throw LimitExceededException(
        'Cannot add task. Today already has ${currentToday.length}/$maxTodayTasks tasks.',
      );
    }

    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: Task.formatDate(date),
      status: TaskStatus.today,
      createdAt: DateTime.now(),
      order: currentToday.length,
    );

    await _taskBox.put(task.id, task);
    return task;
  }

  @override
  Future<Task> addTaskToSomeday({
    required String title,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: '',
      status: TaskStatus.someday,
      createdAt: DateTime.now(),
      order: 0,
    );

    await _taskBox.put(task.id, task);
    return task;
  }

  @override
  Future<Task> replaceTodayTask({
    required String oldTaskId,
    required String newTitle,
    required DateTime date,
  }) async {
    final oldTask = _taskBox.get(oldTaskId);
    if (oldTask != null) {
      // Move old task to someday
      final demotedOldTask = oldTask.copyWith(
        status: TaskStatus.someday,
        date: '',
      );
      await _taskBox.put(oldTaskId, demotedOldTask);
    }

    final newTask = Task(
      id: _uuid.v4(),
      title: newTitle.trim(),
      date: Task.formatDate(date),
      status: TaskStatus.today,
      createdAt: DateTime.now(),
      order: oldTask?.order ?? 0,
    );

    await _taskBox.put(newTask.id, newTask);
    return newTask;
  }

  @override
  Future<void> promoteSomedayToTodayReplace({
    required String somedayTaskId,
    required String replaceOldTaskId,
    required DateTime date,
  }) async {
    final oldTask = _taskBox.get(replaceOldTaskId);
    final somedayTask = _taskBox.get(somedayTaskId);

    if (somedayTask == null) return;

    if (oldTask != null) {
      final demotedOldTask = oldTask.copyWith(
        status: TaskStatus.someday,
        date: '',
      );
      await _taskBox.put(replaceOldTaskId, demotedOldTask);
    }

    final promotedTask = somedayTask.copyWith(
      status: TaskStatus.today,
      date: Task.formatDate(date),
      order: oldTask?.order ?? 0,
    );

    await _taskBox.put(somedayTaskId, promotedTask);
  }

  @override
  Future<Task> toggleTaskDone(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task == null) {
      throw StateError('Task with id $taskId not found');
    }

    final newStatus =
        task.status == TaskStatus.done ? TaskStatus.today : TaskStatus.done;
    final updatedTask = task.copyWith(status: newStatus);

    await _taskBox.put(taskId, updatedTask);
    return updatedTask;
  }

  @override
  Future<Task> moveTaskToSomeday(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task == null) {
      throw StateError('Task with id $taskId not found');
    }

    final updatedTask = task.copyWith(
      status: TaskStatus.someday,
      date: '',
    );

    await _taskBox.put(taskId, updatedTask);
    return updatedTask;
  }

  @override
  Future<Task> moveTaskToToday({
    required String taskId,
    required DateTime date,
  }) async {
    final currentToday = getTodayTasks(date);
    if (currentToday.length >= maxTodayTasks) {
      throw LimitExceededException(
        'Cannot move task to today. Maximum limit of $maxTodayTasks reached.',
      );
    }

    final task = _taskBox.get(taskId);
    if (task == null) {
      throw StateError('Task with id $taskId not found');
    }

    final updatedTask = task.copyWith(
      status: TaskStatus.today,
      date: Task.formatDate(date),
      order: currentToday.length,
    );

    await _taskBox.put(taskId, updatedTask);
    return updatedTask;
  }

  @override
  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  @override
  Future<void> processSummaryDecisions({
    required DateTime currentDate,
    required Map<String, String> decisions,
  }) async {
    final tomorrowStr =
        Task.formatDate(currentDate.add(const Duration(days: 1)));

    for (final entry in decisions.entries) {
      final taskId = entry.key;
      final decision = entry.value;
      final task = _taskBox.get(taskId);
      if (task == null) continue;

      switch (decision) {
        case 'tomorrow':
          final updated = task.copyWith(
            date: tomorrowStr,
            status: TaskStatus.today,
          );
          await _taskBox.put(taskId, updated);
          break;
        case 'someday':
          final updated = task.copyWith(
            date: '',
            status: TaskStatus.someday,
          );
          await _taskBox.put(taskId, updated);
          break;
        case 'delete':
          await _taskBox.delete(taskId);
          break;
      }
    }
  }
}
