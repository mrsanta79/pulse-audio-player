import 'package:flutter/material.dart';

/// Asks for a single line of text, returning it trimmed, or null if the user
/// cancelled or left it blank.
///
/// A widget rather than a bare `showDialog` so the [TextEditingController] has
/// somewhere to be disposed: built inline, it outlives the dialog and leaks.
Future<String?> promptForName(
  BuildContext context, {
  required String title,
  required String hint,
  String confirmLabel = 'Create',
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) =>
        _NamePromptDialog(title: title, hint: hint, confirmLabel: confirmLabel),
  );
  final trimmed = name?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

class _NamePromptDialog extends StatefulWidget {
  const _NamePromptDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
