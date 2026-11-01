import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';

final taskRepositoryProvider = Provider<TaskRepositoryInterface>((ref) {
  // Will be overridden in main with real Hive box
  throw UnimplementedError();
});

class TodayState {
  final List<Task> tasks;
  final DateTime selectedDate;
  final bool isLoading;

  const TodayState({
    required this.tasks,
    required this.selectedDate,
    this.isLoading = false,
  });

  int get completedCount => tasks.where((t) => t.status == TaskStatus.done).length;
  bool get isFull => tasks.length >= 3;

  TodayState copyWith({
    List<Task>? tasks,
    DateTime? selectedDate,
    bool? isLoading,
  }) {
    return TodayState(
      tasks: tasks ?? this.tasks,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TodayController extends StateNotifier<TodayState> {
  final TaskRepositoryInterface _repository;

  TodayController(this._repository, {DateTime? initialDate})
      : super(TodayState(
          tasks: [],
          selectedDate: initialDate ?? DateTime.now(),
        )) {
    loadTasks();
  }

  void loadTasks() {
    final tasks = _repository.getTodayTasks(state.selectedDate);
    state = state.copyWith(tasks: tasks);
  }

  Future<void> addTask(String title) async {
    try {
      await _repository.addTaskToToday(
        title: title,
        date: state.selectedDate,
      );
      loadTasks();
    } on LimitExceededException {
      rethrow;
    }
  }

  Future<void> toggleDone(String taskId) async {
    await _repository.toggleTaskDone(taskId);
    loadTasks();
  }

  Future<void> replaceTask({
    required String oldTaskId,
    required String newTitle,
  }) async {
    await _repository.replaceTodayTask(
      oldTaskId: oldTaskId,
      newTitle: newTitle,
      date: state.selectedDate,
    );
    loadTasks();
  }

  Future<void> moveToSomeday(String taskId) async {
    await _repository.moveTaskToSomeday(taskId);
    loadTasks();
  }

  Future<void> addDirectlyToSomeday(String title) async {
    await _repository.addTaskToSomeday(title: title);
  }
}

final todayControllerProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TodayController(repo);
});
