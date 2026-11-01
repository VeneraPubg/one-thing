import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';
import 'package:one_thing/features/today/controllers/today_controller.dart';

class SomedayState {
  final List<Task> tasks;
  final bool isLoading;

  const SomedayState({
    required this.tasks,
    this.isLoading = false,
  });

  SomedayState copyWith({
    List<Task>? tasks,
    bool? isLoading,
  }) {
    return SomedayState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SomedayController extends StateNotifier<SomedayState> {
  final TaskRepositoryInterface _repository;
  final TodayController _todayController;

  SomedayController(this._repository, this._todayController)
      : super(const SomedayState(tasks: [])) {
    loadTasks();
  }

  /// Reloads the someday list from the repository.
  /// Skips redundant state updates when the list hasn't changed.
  void loadTasks() {
    final tasks = _repository.getSomedayTasks();
    if (!listEquals(tasks, state.tasks)) {
      state = state.copyWith(tasks: tasks);
    }
  }

  /// Takes a someday task and moves it to Today.
  /// Only succeeds if today has fewer than 3 tasks.
  /// Throws [LimitExceededException] if today is already full.
  Future<void> takeToToday(String taskId) async {
    await _repository.moveTaskToToday(
      taskId: taskId,
      date: DateTime.now(),
    );
    _todayController.loadTasks();
    loadTasks();
  }

  /// When today is full: swap a someday task with one of the today tasks.
  /// The replaced today task is demoted to someday.
  Future<void> takeToTodayReplace({
    required String somedayTaskId,
    required String replaceOldTaskId,
  }) async {
    await _repository.promoteSomedayToTodayReplace(
      somedayTaskId: somedayTaskId,
      replaceOldTaskId: replaceOldTaskId,
      date: DateTime.now(),
    );
    _todayController.loadTasks();
    loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    loadTasks();
  }

  Future<void> addTask(String title) async {
    await _repository.addTaskToSomeday(title: title);
    loadTasks();
  }
}

final somedayControllerProvider =
    StateNotifierProvider<SomedayController, SomedayState>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final todayController = ref.watch(todayControllerProvider.notifier);
  return SomedayController(repo, todayController);
});
