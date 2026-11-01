import 'package:flutter/material.dart';

class TaskSlotCard extends StatelessWidget {
  final String? title;
  final bool isCompleted;
  final VoidCallback? onTapCheckbox;
  final VoidCallback? onTapCard;
  final bool isEmpty;
  final String? emptyPlaceholderText;

  const TaskSlotCard({
    super.key,
    this.title,
    this.isCompleted = false,
    this.onTapCheckbox,
    this.onTapCard,
    this.isEmpty = false,
    this.emptyPlaceholderText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isEmpty) {
      return Semantics(
        button: true,
        label: emptyPlaceholderText ?? 'Empty task slot. Tap to add task.',
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF444446) : const Color(0xFFC7C9C0),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282B26) : const Color(0xFFF1F3EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    emptyPlaceholderText ?? 'Место для одной задачи',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Active or completed task card
    final backgroundColor = isCompleted
        ? (isDark ? const Color(0xFF233023) : const Color(0xFFEBF1E8))
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final borderColor = isCompleted
        ? Colors.transparent
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E4DE));

    return Semantics(
      checked: isCompleted,
      button: true,
      label: 'Task: $title. Status: ${isCompleted ? "Completed" : "Active"}. Tap checkbox to toggle.',
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTapCard,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: isCompleted ? 'Mark as active' : 'Mark as completed',
                    child: InkWell(
                      onTap: onTapCheckbox,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? (isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.transparent
                                : (isDark ? const Color(0xFFA1A1A6) : const Color(0xFFC7C9C0)),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: isDark ? const Color(0xFF121212) : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? (isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73))
                            : theme.colorScheme.onSurface,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
