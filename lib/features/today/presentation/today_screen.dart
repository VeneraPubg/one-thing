import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:one_thing/data/models/task.dart';
import 'package:one_thing/data/models/task_status.dart';
import 'package:one_thing/data/repositories/task_repository_interface.dart';
import 'package:one_thing/features/someday/controllers/someday_controller.dart';
import 'package:one_thing/shared/widgets/secondary_button.dart';
import 'package:one_thing/shared/widgets/task_slot_card.dart';
import '../controllers/today_controller.dart';
import 'add_task_sheet.dart';
import 'limit_reached_dialog.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = state.selectedDate;
    final dateTitle = DateFormat.EEEE('ru').format(now).toString();
    final dateSub = DateFormat.MMMM('ru').add_d().format(now);

    final doneCount = state.completedCount;
    final totalCount = state.tasks.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сегодня',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_capitalize(dateTitle)}, $dateSub',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Semantics(
              label: 'Добавить задачу',
              button: true,
              child: IconButton(
                tooltip: 'Добавить задачу',
                onPressed: () =>
                    _onAddPressed(context, ref, controller, state),
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 24,
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(
                  label: '${state.isFull ? 3 : state.tasks.length} из 3 слотов занято',
                  isFilled: true,
                  isDark: isDark,
                ),
                _StatusChip(
                  label: 'Выполнено: $doneCount из $totalCount',
                  isFilled: false,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ..._buildSlots(
              tasks: state.tasks,
              isDark: isDark,
              controller: controller,
            ),
            const SizedBox(height: 32),
            if (state.tasks.isNotEmpty && doneCount == totalCount)
              _footerSummary(context)
            else
              _footerSummary(context),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Всё важное уже здесь',
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

  List<Widget> _buildSlots({
    required List<Task> tasks,
    required bool isDark,
    required TodayController controller,
  }) {
    final widgets = <Widget>[];

    for (var i = 0; i < 3; i++) {
      if (i < tasks.length) {
        final task = tasks[i];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnimatedTaskSlot(
              key: ValueKey(task.id),
              task: task,
              onTapCheckbox: () => controller.toggleDone(task.id),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskSlotCard(
              key: ValueKey('empty_slot_$i'),
              isEmpty: true,
              emptyPlaceholderText: 'Место для одной задачи',
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _footerSummary(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.go('/summary'),
          child: const Text('Подвести итог →'),
        ),
      ],
    );
  }

  void _onAddPressed(BuildContext context, WidgetRef ref,
      TodayController controller, TodayState state) {
    if (state.isFull) {
      // Limit reached: open the sheet to get a title, then the limit dialog.
      _showAddTaskSheet(context, ref, controller);
      return;
    }
    _showAddTaskSheet(context, ref, controller);
  }

  void _showLimitReachedDialog(
      BuildContext context, WidgetRef ref, TodayController controller, String pendingTitle) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => LimitReachedDialog(
        pendingTitle: pendingTitle,
        onPostpone: () async {
          final somedayController =
              ref.read(somedayControllerProvider.notifier);
          await somedayController.addTask(pendingTitle);
        },
        onReplace: () {
          _showReplaceFromTodaySheet(context, ref, controller, pendingTitle);
        },
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref,
      TodayController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddTaskSheet(
        date: DateTime.now(),
        onSubmit: (title) async {
          try {
            await controller.addTask(title);
          } on LimitExceededException {
            // Slots became full while sheet was open → limit dialog.
            // AddTaskSheet pops itself; we only show the dialog here.
            if (context.mounted) {
              _showLimitReachedDialog(context, ref, controller, title);
            }
            return;
          }
          ref.read(somedayControllerProvider.notifier).loadTasks();
        },
      ),
    );
  }

  void _showReplaceFromTodaySheet(BuildContext context, WidgetRef ref,
      TodayController controller, String newTitle) {
    final todayTasks = ref.read(todayControllerProvider).tasks;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заменить одну из трёх',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Заменённая задача отправится в «Когда-нибудь».',
              style: TextStyle(fontSize: 14, color: Color(0xFF6E6E73)),
            ),
            const SizedBox(height: 20),
            ...todayTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SecondaryButton(
                  label: task.title,
                  onPressed: () async {
                    await controller.replaceTask(
                      oldTaskId: task.id,
                      newTitle: newTitle,
                    );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isFilled;
  final bool isDark;

  const _StatusChip({
    required this.label,
    required this.isFilled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isFilled
            ? (isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8))
            : (isDark ? const Color(0xFF282B26) : const Color(0xFFF1F3EE)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isFilled
              ? (isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C))
              : (isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73)),
        ),
      ),
    );
  }
}

class _AnimatedTaskSlot extends StatelessWidget {
  final Task task;
  final VoidCallback? onTapCheckbox;

  const _AnimatedTaskSlot({
    super.key,
    required this.task,
    this.onTapCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${task.id}_${task.status == TaskStatus.done}'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) {
          return Opacity(
            opacity: 0.4 + 0.6 * value,
            child: child,
          );
        },
        child: TaskSlotCard(
          title: task.title,
          isCompleted: task.status == TaskStatus.done,
          onTapCheckbox: onTapCheckbox,
        ),
      ),
    );
  }
}
