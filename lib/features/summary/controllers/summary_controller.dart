import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';
import 'package:one_thing/features/today/controllers/today_controller.dart';

class SummaryState {
  final DateTime date;
  final List<Task> tasks;
  final Map<String, String> decisions;
  final bool isFinalized;

  const SummaryState({
    required this.date,
    required this.tasks,
    this.decisions = const {},
    this.isFinalized = false,
  });

  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.done).length;

  List<Task> get uncompletedTasks =>
      tasks.where((t) => t.status != TaskStatus.done).toList();

  SummaryState copyWith({
    DateTime? date,
    List<Task>? tasks,
    Map<String, String>? decisions,
    bool? isFinalized,
  }) {
    return SummaryState(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      decisions: decisions ?? this.decisions,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }
}

class SummaryController extends StateNotifier<SummaryState> {
  final TaskRepositoryInterface _repository;
  final TodayController _todayController;

  SummaryController(this._repository, this._todayController,
      {DateTime? date})
      : super(SummaryState(date: date ?? DateTime.now(), tasks: [])) {
    _load();
  }

  void _load() {
    final tasks = _repository.getTodayTasks(state.date);
    state = state.copyWith(tasks: tasks);
  }

  void setDecision(String taskId, String decision) {
    final updated = Map<String, String>.from(state.decisions);
    if (decision.isEmpty) {
      updated.remove(taskId);
    } else {
      updated[taskId] = decision;
    }
    state = state.copyWith(decisions: updated);
  }

  /// Applies all selected decisions atomically and closes the day.
  Future<void> finalize() async {
    await _repository.processSummaryDecisions(
      currentDate: state.date,
      decisions: state.decisions,
    );
    _todayController.loadTasks();
    state = state.copyWith(isFinalized: true);
  }
}

final summaryControllerProvider =
    StateNotifierProvider<SummaryController, SummaryState>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  final todayController = ref.watch(todayControllerProvider.notifier);
  return SummaryController(repo, todayController);
});
