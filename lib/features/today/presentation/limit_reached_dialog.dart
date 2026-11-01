import 'package:flutter/material.dart';
import 'package:one_thing/shared/widgets/primary_button.dart';
import 'package:one_thing/shared/widgets/secondary_button.dart';

class LimitReachedDialog extends StatelessWidget {
  final VoidCallback onPostpone;
  final VoidCallback onReplace;
  final String? pendingTitle;

  const LimitReachedDialog({
    super.key,
    required this.onPostpone,
    required this.onReplace,
    this.pendingTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '3 из 3 занято',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              pendingTitle != null ? '«$pendingTitle»' : 'Новая задача',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'На сегодня достаточно',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Три задачи уже выбраны. Новую можно отложить или поставить вместо одной из них.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Отложить в когда-нибудь',
              onPressed: () {
                Navigator.of(context).pop();
                onPostpone();
              },
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Заменить одну из трёх',
              onPressed: () {
                Navigator.of(context).pop();
                onReplace();
              },
            ),
          ],
        ),
      ),
    );
  }
}
