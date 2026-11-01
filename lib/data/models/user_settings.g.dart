// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 4;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      notificationHour: fields[0] as int,
      notificationMinute: fields[1] as int,
      notificationsEnabled: fields[2] as bool,
      uncompletedBehavior: fields[3] as UncompletedDefaultBehavior,
      themeMode: fields[4] as ThemeModeSetting,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.notificationHour)
      ..writeByte(1)
      ..write(obj.notificationMinute)
      ..writeByte(2)
      ..write(obj.notificationsEnabled)
      ..writeByte(3)
      ..write(obj.uncompletedBehavior)
      ..writeByte(4)
      ..write(obj.themeMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemeModeSettingAdapter extends TypeAdapter<ThemeModeSetting> {
  @override
  final int typeId = 2;

  @override
  ThemeModeSetting read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ThemeModeSetting.system;
      case 1:
        return ThemeModeSetting.light;
      case 2:
        return ThemeModeSetting.dark;
      default:
        return ThemeModeSetting.system;
    }
  }

  @override
  void write(BinaryWriter writer, ThemeModeSetting obj) {
    switch (obj) {
      case ThemeModeSetting.system:
        writer.writeByte(0);
        break;
      case ThemeModeSetting.light:
        writer.writeByte(1);
        break;
      case ThemeModeSetting.dark:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeModeSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UncompletedDefaultBehaviorAdapter
    extends TypeAdapter<UncompletedDefaultBehavior> {
  @override
  final int typeId = 3;

  @override
  UncompletedDefaultBehavior read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UncompletedDefaultBehavior.ask;
      case 1:
        return UncompletedDefaultBehavior.tomorrow;
      default:
        return UncompletedDefaultBehavior.ask;
    }
  }

  @override
  void write(BinaryWriter writer, UncompletedDefaultBehavior obj) {
    switch (obj) {
      case UncompletedDefaultBehavior.ask:
        writer.writeByte(0);
        break;
      case UncompletedDefaultBehavior.tomorrow:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UncompletedDefaultBehaviorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
