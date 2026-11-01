import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'data/models/task.dart';
import 'data/models/task_status.dart';
import 'data/models/user_settings.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/task_repository.dart';
import 'features/today/controllers/today_controller.dart';
import 'services/notification_service.dart';
import 'services/widget_bridge_service.dart';
import 'services/widget_sync_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ThemeModeSettingAdapter());
  Hive.registerAdapter(UncompletedDefaultBehaviorAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

  final taskBox = await Hive.openBox<Task>('tasks');
  final settingsBox = await Hive.openBox<UserSettings>('settings');

  final taskRepository = TaskRepository(taskBox);
  final settingsRepository = SettingsRepository(settingsBox);
  final initialSettings = settingsRepository.load();

  TaskRepositoryProviderHolder.instance = taskRepository;

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final widgetBridge = WidgetBridgeService();
  await widgetBridge.initialize();

  await initializeDateFormatting('ru', null);

  Future<void> applySettings(UserSettings s) async {
    if (s.notificationsEnabled) {
      await notificationService.scheduleDailySummary(
        hour: s.notificationHour,
        minute: s.notificationMinute,
        title: 'Пора подвести итог',
        body: 'Как прошли три главные задачи дня?',
      );
    } else {
      await notificationService.cancelDailySummary();
    }
  }

  final settingsController = SettingsController(
    settingsRepository,
    applySettings,
    initial: initialSettings,
  );

  final widgetSync = WidgetSyncService(taskRepository, widgetBridge);

  runApp(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(taskRepository),
        settingsControllerProvider.overrideWith((ref) => settingsController),
      ],
      child: OneThingApp(
        notificationService: notificationService,
        widgetSync: widgetSync,
        applySettings: applySettings,
      ),
    ),
  );
}

class OneThingApp extends ConsumerStatefulWidget {
  final NotificationService notificationService;
  final WidgetSyncService widgetSync;
  final Future<void> Function(UserSettings) applySettings;

  const OneThingApp({
    super.key,
    required this.notificationService,
    required this.widgetSync,
    required this.applySettings,
  });

  @override
  ConsumerState<OneThingApp> createState() => _OneThingAppState();
}

class _OneThingAppState extends ConsumerState<OneThingApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build();
    _router.routerDelegate.addListener(_onRouteChanged);

    widget.notificationService.onNotificationTap = (payload) {
      if (payload == 'daily_summary') {
        _router.go(AppRouter.summaryPath);
      }
    };

    WidgetBridgeService().registerToggleCallback((taskId) async {
      await TaskRepositoryProviderHolder.instance.toggleTaskDone(taskId);
      await widget.widgetSync.syncTodayWidget(DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.widgetSync.syncTodayWidget(DateTime.now());
    });
  }

  void _onRouteChanged() {
    widget.widgetSync.syncTodayWidget(DateTime.now());
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  ThemeMode _resolveTheme(ThemeModeSetting mode) {
    switch (mode) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme reacts to settings changes in real time.
    final themeSetting = ref.watch(settingsControllerProvider).themeMode;

    return MaterialApp.router(
      title: 'One Thing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveTheme(themeSetting),
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      locale: const Locale('ru'),
    );
  }
}
