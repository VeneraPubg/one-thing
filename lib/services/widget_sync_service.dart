import 'package:one_thing/data/models/task_status.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';
import 'package:one_thing/services/widget_bridge_service.dart';

/// Keeps the home screen widget in sync with today's tasks.
class WidgetSyncService {
  final TaskRepositoryInterface _repository;
  final WidgetBridgeService _bridge;

  WidgetSyncService(this._repository, this._bridge);

  Future<void> syncTodayWidget(DateTime date) async {
    final tasks = _repository.getTodayTasks(date);

    // Always render exactly 3 slots — pad with empty ones.
    final slots = <({String id, String title, bool isDone})>[];
    for (final task in tasks.take(3)) {
      slots.add((
        id: task.id,
        title: task.title,
        isDone: task.status == TaskStatus.done,
      ));
    }

    await _bridge.updateTodayWidget(
      dateLabel: _formatDate(date),
      tasks: slots,
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      '',
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];
    const months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${weekdays[date.weekday]}, ${date.day} ${months[date.month]}';
  }
}

/// Background callback dispatcher for the home widget toggle action.
/// Registered in main.dart; toggles the task and refreshes the widget.
@pragma('vm:entry-point')
Future<void> widgetToggleCallback(String taskId) async {
  // Runs in a background isolate: use the repository holder set up in main.
  final repository = TaskRepositoryProviderHolder.instance;
  await repository.toggleTaskDone(taskId);

  final sync = WidgetSyncService(
    repository,
    WidgetBridgeService(),
  );
  await sync.syncTodayWidget(DateTime.now());
}

/// Holder for the repository, shared with background isolates.
/// Set in main.dart after opening the Hive box.
class TaskRepositoryProviderHolder {
  static TaskRepositoryInterface? _instance;
  static TaskRepositoryInterface get instance =>
      _instance ?? (throw StateError('Repository not initialized'));
  static set instance(TaskRepositoryInterface repo) => _instance = repo;
}
