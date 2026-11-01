import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text(
          'Настройки',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _sectionTitle(context, 'Вечернее напоминание'),
            _SettingsCard(
              isDark: isDark,
              child: SwitchListTile(
                title: Text(
                  'Подвести итог '
                  '${settings.notificationHour.toString().padLeft(2, '0')}:'
                  '${settings.notificationMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: settings.notificationsEnabled,
                onChanged: (enabled) async {
                  await controller.setNotificationsEnabled(enabled);
                },
                activeTrackColor: isDark
                    ? const Color(0xFF233023)
                    : const Color(0xFFEBF1E8),
                activeColor:
                    isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
              ),
            ),
            const SizedBox(height: 8),
            if (settings.notificationsEnabled)
              _SettingsCard(
                isDark: isDark,
                child: ListTile(
                  title: const Text(
                    'Время напоминания',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    '${settings.notificationHour.toString().padLeft(2, '0')}:'
                    '${settings.notificationMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFAAC59D)
                          : const Color(0xFF42664C),
                    ),
                  ),
                  onTap: () => _pickTime(context, settings, controller),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Одно тихое напоминание в день. Без серии повторных уведомлений.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFFA1A1A6)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _sectionTitle(context, 'Если задача осталась'),
            _SettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _BehaviorOption(
                    label: 'Спрашивать в итоге дня',
                    description: 'Не переносить автоматически',
                    value: UncompletedDefaultBehavior.ask,
                    groupValue: settings.uncompletedBehavior,
                    isDark: isDark,
                    onChanged: (v) => controller.setUncompletedBehavior(v!),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE2E4DE),
                  ),
                  _BehaviorOption(
                    label: 'Перенести на завтра',
                    description: 'Несделанные задачи ждут завтра',
                    value: UncompletedDefaultBehavior.tomorrow,
                    groupValue: settings.uncompletedBehavior,
                    isDark: isDark,
                    onChanged: (v) => controller.setUncompletedBehavior(v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _sectionTitle(context, 'Тема'),
            _SettingsCard(
              isDark: isDark,
              child: Row(
                children: [
                  Expanded(
                    child: _ThemeOption(
                      label: 'Светлая',
                      value: ThemeModeSetting.light,
                      groupValue: settings.themeMode,
                      isDark: isDark,
                      icon: Icons.light_mode_outlined,
                      onChanged: (v) => controller.setThemeMode(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Тёмная',
                      value: ThemeModeSetting.dark,
                      groupValue: settings.themeMode,
                      isDark: isDark,
                      icon: Icons.dark_mode_outlined,
                      onChanged: (v) => controller.setThemeMode(v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Системная',
                      value: ThemeModeSetting.system,
                      groupValue: settings.themeMode,
                      isDark: isDark,
                      icon: Icons.settings_suggest_outlined,
                      onChanged: (v) => controller.setThemeMode(v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Text(
                    'One Thing — Версия 1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA1A1A6)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Меньше задач. Больше внимания.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFA1A1A6)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    UserSettings settings,
    SettingsController controller,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      builder: (context, child) => Theme.of(context).brightness == Brightness.dark
          ? Theme(data: ThemeData.dark(), child: child!)
          : Theme(data: ThemeData.light(), child: child!),
    );

    if (picked != null) {
      await controller.setNotificationTime(picked.hour, picked.minute);
    }
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _SettingsCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E4DE),
        ),
      ),
      child: child,
    );
  }
}

class _BehaviorOption extends StatelessWidget {
  final String label;
  final String description;
  final UncompletedDefaultBehavior value;
  final UncompletedDefaultBehavior groupValue;
  final bool isDark;
  final ValueChanged<UncompletedDefaultBehavior?> onChanged;

  const _BehaviorOption({
    required this.label,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<UncompletedDefaultBehavior>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
        ),
      ),
      activeColor: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeModeSetting value;
  final ThemeModeSetting groupValue;
  final bool isDark;
  final ValueChanged<ThemeModeSetting?> onChanged;

  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Тема: $label',
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark
                        ? const Color(0xFFAAC59D)
                        : const Color(0xFF42664C))
                    : (isDark
                        ? const Color(0xFFA1A1A6)
                        : const Color(0xFF6E6E73)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
            ],
          ),
        ),
      ),
    );
  }
}
