import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task.dart';
import '../../../shared/widgets/primary_button.dart';
import '../controllers/summary_controller.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(summaryControllerProvider);
    final controller = ref.read(summaryControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateLabel =
        DateFormat('d MMMM', 'ru').format(state.date);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сегодня',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Итог · $dateLabel',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: state.isFinalized
            ? _buildFinalized(context, isDark)
            : _buildSummary(context, ref, state, controller, isDark),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    WidgetRef ref,
    SummaryState state,
    SummaryController controller,
    bool isDark,
  ) {
    final uncompleted = state.uncompletedTasks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '${state.completedCount} из 3 сделано',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Отличная работа.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.tasks.isEmpty) ...[
          Center(
            child: Text(
              'На сегодня задач не было.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              ),
            ),
          ),
        ] else ...[
          Text(
            'Что сделаем с оставшимся?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...uncompleted.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UncompletedTaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  selected: state.decisions[task.id],
                  onSelected: (decision) =>
                      controller.setDecision(task.id, decision),
                ),
              )),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Не всё нужно успеть за один день.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Готово',
            onPressed: () => controller.finalize(),
          ),
          if (state.isFinalized) const SizedBox.shrink(),
        ],
      ],
    );
  }

  Widget _buildFinalized(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
          ),
          const SizedBox(height: 16),
          const Text(
            'Итог подведён',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Завтра ждут только выбранные задачи.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 200),
            child: TextButton(
              onPressed: () => context.go('/today'),
              style: TextButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text(
                'Вернуться к задачам',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UncompletedTaskCard extends StatelessWidget {
  final Task task;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _UncompletedTaskCard({
    super.key,
    required this.task,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E4DE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DecisionChip(
                  label: 'На завтра',
                  isSelected: selected == 'tomorrow',
                  isDark: isDark,
                  onTap: () => onSelected(
                      selected == 'tomorrow' ? '' : 'tomorrow'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DecisionChip(
                  label: 'В когда-нибудь',
                  isSelected: selected == 'someday',
                  isDark: isDark,
                  onTap: () =>
                      onSelected(selected == 'someday' ? '' : 'someday'),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Удалить задачу',
                child: _DecisionChip(
                  label: '',
                  icon: Icons.delete_outline,
                  isSelected: selected == 'delete',
                  isDark: isDark,
                  onTap: () =>
                      onSelected(selected == 'delete' ? '' : 'delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DecisionChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: isSelected
            ? (isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8))
            : (isDark ? const Color(0xFF282B26) : const Color(0xFFF1F3EE)),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? (isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C))
                        : (isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73)),
                  )
                else
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFFAAC59D)
                                : const Color(0xFF42664C))
                            : (isDark
                                ? const Color(0xFFA1A1A6)
                                : const Color(0xFF6E6E73)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
