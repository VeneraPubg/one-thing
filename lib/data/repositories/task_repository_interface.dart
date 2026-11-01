import '../models/task.dart';

class LimitExceededException implements Exception {
  final String message;
  LimitExceededException([this.message = 'Maximum 3 tasks allowed for today']);

  @override
  String toString() => 'LimitExceededException: $message';
}

abstract class TaskRepositoryInterface {
  /// Returns tasks for today (both active and completed for the date).
  List<Task> getTodayTasks(DateTime date);

  /// Returns active tasks for today (status: today or done).
  List<Task> getActiveTodayTasks(DateTime date);

  /// Returns tasks in "Someday" backlog (status: someday).
  List<Task> getSomedayTasks();

  /// Adds a new task to Today.
  /// Throws [LimitExceededException] if there are already 3 tasks for today.
  Future<Task> addTaskToToday({
    required String title,
    required DateTime date,
  });

  /// Adds a task directly to "Someday".
  Future<Task> addTaskToSomeday({
    required String title,
  });

  /// Replaces an existing active today task with a new title or existing task.
  /// The old task is moved to "Someday".
  Future<Task> replaceTodayTask({
    required String oldTaskId,
    required String newTitle,
    required DateTime date,
  });

  /// Moves a task from "Someday" to Today replacing an old task.
  Future<void> promoteSomedayToTodayReplace({
    required String somedayTaskId,
    required String replaceOldTaskId,
    required DateTime date,
  });

  /// Toggles status between today and done.
  Future<Task> toggleTaskDone(String taskId);

  /// Moves task from Today to Someday.
  Future<Task> moveTaskToSomeday(String taskId);

  /// Moves task from Someday to Today.
  /// Throws [LimitExceededException] if today already has 3 tasks.
  Future<Task> moveTaskToToday({
    required String taskId,
    required DateTime date,
  });

  /// Deletes a task by ID.
  Future<void> deleteTask(String id);

  /// Process end-of-day summary decisions for uncompleted tasks:
  /// Actions per task ID: 'tomorrow', 'someday', or 'delete'
  Future<void> processSummaryDecisions({
    required DateTime currentDate,
    required Map<String, String> decisions,
  });
}
