import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../today/controllers/today_controller.dart';
import '../controllers/someday_controller.dart';

class SomedayScreen extends ConsumerWidget {
  const SomedayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Repository is the source of truth: refresh the list on every build
    // so tasks added from the limit dialog / summary show up here.
    ref.read(somedayControllerProvider.notifier).loadTasks();

    final somedayState = ref.watch(somedayControllerProvider);
    final somedayController = ref.read(somedayControllerProvider.notifier);
    final todayState = ref.watch(todayControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text(
          'Когда-нибудь',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Здесь идеи могут подождать. Без сроков и обязательств.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (todayState.isFull) ...[
              _FullSlotsBanner(isDark: isDark),
              const SizedBox(height: 12),
            ],
            if (somedayState.tasks.isEmpty)
              _EmptyState(isDark: isDark)
            else
              ..._buildSomedayTasks(
                context,
                ref,
                somedayState.tasks,
                somedayController,
                todayState.isFull,
              ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                todayState.isFull
                    ? 'Чётвёртой задачи в дне не появится.'
                    : 'Взять на сегодня — одним касанием.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSomedayTasks(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    SomedayController controller,
    bool isTodayFull,
  ) {
    return tasks.map((task) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SomedayTaskCard(
          key: ValueKey(task.id),
          task: task,
          onTakeToToday: isTodayFull
              ? () => _showReplacePicker(context, ref, controller, task)
              : () => _takeToToday(context, controller, task),
          onDelete: () => controller.deleteTask(task.id),
        ),
      );
    }).toList();
  }

  void _takeToToday(
    BuildContext context,
    SomedayController controller,
    Task task,
  ) async {
    try {
      await controller.takeToToday(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${task.title}» — взята на сегодня'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // LimitExceededException — today became full meanwhile
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сегодня уже заняты все 3 слота'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showReplacePicker(
    BuildContext context,
    WidgetRef ref,
    SomedayController controller,
    Task somedayTask,
  ) {
    final todayState = ref.watch(todayControllerProvider);
    final todayTasks = todayState.tasks;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ReplacePickerSheet(
        somedayTaskTitle: somedayTask.title,
        todayTasks: todayTasks,
        onConfirm: (oldTaskId) async {
          await controller.takeToTodayReplace(
            somedayTaskId: somedayTask.id,
            replaceOldTaskId: oldTaskId,
          );
        },
      ),
    );
  }
}

class _FullSlotsBanner extends StatelessWidget {
  final bool isDark;

  const _FullSlotsBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282B26) : const Color(0xFFF1F3EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Сегодня заняты все 3 слота. Чтобы взять задачу, нужно выбрать одну из трёх на замену.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.auto_awesome,
          size: 48,
          color: isDark ? const Color(0xFF444446) : const Color(0xFFC7C9C0),
        ),
        const SizedBox(height: 16),
        Text(
          'Пока пусто. Отложенные задачи появятся здесь.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SomedayTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTakeToToday;
  final VoidCallback onDelete;

  const _SomedayTaskCard({
    super.key,
    required this.task,
    required this.onTakeToToday,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E4DE),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Удалить задачу',
                  child: IconButton(
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Взять на сегодня →',
              onPressed: onTakeToToday,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacePickerSheet extends StatelessWidget {
  final String somedayTaskTitle;
  final List<Task> todayTasks;
  final Future<void> Function(String oldTaskId) onConfirm;

  const _ReplacePickerSheet({
    required this.somedayTaskTitle,
    required this.todayTasks,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Что отправить в «когда-нибудь»?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '«$somedayTaskTitle» займёт её место на сегодня.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 20),
          ...todayTasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SecondaryButton(
                label: task.title,
                onPressed: () async {
                  await onConfirm(task.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
