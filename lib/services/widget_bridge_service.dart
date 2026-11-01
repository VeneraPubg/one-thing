import 'package:home_widget/home_widget.dart';

/// Bridge between the Flutter app and native home screen widgets
/// (Android AppWidget + iOS WidgetKit) via the home_widget package.
class WidgetBridgeService {
  static const appGroupId = 'group.com.onething.app';
  static const tasksKey = 'widget.tasks';
  static const dateKey = 'widget.date';
  static const counterKey = 'widget.counter';
  static const androidWidgetName = 'OneThingWidgetProvider';

  /// Configures the App Group used to share data with the native widget.
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Pushes today's tasks to the native widget storage
  /// and triggers a widget update.
  ///
  /// [tasks] — up to 3 today tasks: each {id, title, isDone}.
  Future<void> updateTodayWidget({
    required String dateLabel,
    required List<({String id, String title, bool isDone})> tasks,
  }) async {
    final doneCount = tasks.where((t) => t.isDone).length;
    final counterLabel =
        '$doneCount из ${tasks.isEmpty ? 3 : tasks.length} сделано';

    // Serialize as a simple string format: id|isDone|title;;id|isDone|title
    final serialized = tasks
        .map((t) => '${t.id}|${t.isDone ? 1 : 0}|${t.title}')
        .join(';;');

    await HomeWidget.saveWidgetData<String>(tasksKey, serialized);
    await HomeWidget.saveWidgetData<String>(dateKey, dateLabel);
    await HomeWidget.saveWidgetData<String>(counterKey, counterLabel);
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }

  /// Listens for taps on widget checkboxes (and cold start from widget).
  /// [onToggle] receives the tapped task id.
  Future<void> registerToggleCallback(
    Future<void> Function(String taskId) onToggle,
  ) async {
    // Handle taps while the app is running.
    HomeWidget.widgetClicked.listen((Uri? uri) {
      final taskId = _taskIdFromUri(uri);
      if (taskId != null) {
        onToggle(taskId);
      }
    });

    // Handle a cold start launched from the widget.
    final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    final taskId = _taskIdFromUri(initial);
    if (taskId != null) {
      await onToggle(taskId);
    }
  }

  String? _taskIdFromUri(Uri? uri) {
    if (uri == null) return null;
    if (!uri.toString().contains('toggleTask')) return null;
    return uri.queryParameters['taskId'];
  }
}
