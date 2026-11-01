import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  final Box<UserSettings> _box;
  static const _settingsKey = 'app_settings';

  SettingsRepository(this._box);

  UserSettings load() {
    final settings = _box.get(_settingsKey);
    if (settings != null) return settings;

    final defaults = UserSettings();
    _box.put(_settingsKey, defaults);
    return defaults;
  }

  Future<void> save(UserSettings settings) async {
    await _box.put(_settingsKey, settings);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError();
});

class SettingsController extends StateNotifier<UserSettings> {
  final SettingsRepository _repository;
  final void Function(UserSettings) _onSettingsChanged;

  SettingsController(this._repository, this._onSettingsChanged,
      {required UserSettings initial})
      : super(initial);

  Future<void> setNotificationTime(int hour, int minute) async {
    state = state.copyWith(notificationHour: hour, notificationMinute: minute);
    await _repository.save(state);
    _onSettingsChanged(state);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _repository.save(state);
    _onSettingsChanged(state);
  }

  Future<void> setUncompletedBehavior(UncompletedDefaultBehavior behavior) async {
    state = state.copyWith(uncompletedBehavior: behavior);
    await _repository.save(state);
    _onSettingsChanged(state);
  }

  Future<void> setThemeMode(ThemeModeSetting mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.save(state);
    _onSettingsChanged(state);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, UserSettings>((ref) {
  // Overridden in main.dart via ProviderScope.overrides.
  throw UnimplementedError();
});
