import 'package:hive/hive.dart';

part 'task_status.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  today,

  @HiveField(1)
  done,

  @HiveField(2)
  someday,
}
