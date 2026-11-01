import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 2)
enum ThemeModeSetting {
  @HiveField(0)
  system,

  @HiveField(1)
  light,

  @HiveField(2)
  dark,
}

@HiveType(typeId: 3)
enum UncompletedDefaultBehavior {
  @HiveField(0)
  ask, // Спрашивать в итоге дня
  @HiveField(1)
  tomorrow, // Переносить на завтра автоматически
}

@HiveType(typeId: 4)
class UserSettings extends HiveObject {
  @HiveField(0)
  int notificationHour;

  @HiveField(1)
  int notificationMinute;

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  UncompletedDefaultBehavior uncompletedBehavior;

  @HiveField(4)
  ThemeModeSetting themeMode;

  UserSettings({
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = true,
    this.uncompletedBehavior = UncompletedDefaultBehavior.ask,
    this.themeMode = ThemeModeSetting.system,
  });

  UserSettings copyWith({
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    UncompletedDefaultBehavior? uncompletedBehavior,
    ThemeModeSetting? themeMode,
  }) {
    return UserSettings(
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      uncompletedBehavior: uncompletedBehavior ?? this.uncompletedBehavior,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
