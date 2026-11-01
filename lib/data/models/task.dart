import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'task_status.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String date; // YYYY-MM-DD

  @HiveField(3)
  final TaskStatus status;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final int order;

  const Task({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.order,
  });

  /// Normalize DateTime to YYYY-MM-DD string format
  static String formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Task copyWith({
    String? id,
    String? title,
    String? date,
    TaskStatus? status,
    DateTime? createdAt,
    int? order,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [id, title, date, status, createdAt, order];
}
