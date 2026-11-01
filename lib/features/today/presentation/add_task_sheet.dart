import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/primary_button.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final Future<void> Function(String title) onSubmit;

  const AddTaskSheet({
    super.key,
    required this.date,
    required this.onSubmit,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  bool _isNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _isNotEmpty) {
        setState(() {
          _isNotEmpty = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmit(title);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ещё одно важное дело',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Эта задача займёт последний, третий слот на сегодня.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Что сделаем сегодня?',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFFC7C9C0),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF282B26) : const Color(0xFFF1F3EE),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.eco_outlined,
                size: 16,
                color: isDark ? const Color(0xFFAAC59D) : const Color(0xFF42664C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Небольшой и понятный шаг — уже хорошая задача.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E6E73),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Сохранить',
            onPressed: _isNotEmpty ? _submit : null,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
