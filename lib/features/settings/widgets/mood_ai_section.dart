import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';

class MoodAiSection extends ConsumerStatefulWidget {
  const MoodAiSection({super.key});

  @override
  ConsumerState<MoodAiSection> createState() => _MoodAiSectionState();
}

class _MoodAiSectionState extends ConsumerState<MoodAiSection> {
  final _keyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(moodCategorizationServiceProvider);
      final key = await service.getApiKey();
      final model = await service.getModel();
      if (!mounted) return;
      setState(() {
        _hasKey = key?.isNotEmpty == true;
        _modelController.text = model;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load Mood AI settings: $error')),
      );
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(moodCategorizationServiceProvider);
      if (_keyController.text.isNotEmpty) {
        await service.setApiKey(_keyController.text);
        _keyController.clear();
      }
      if (_modelController.text.trim().isNotEmpty) {
        await service.setModel(_modelController.text);
      }
      final key = await service.getApiKey();
      if (!mounted) return;
      setState(() {
        _hasKey = key?.isNotEmpty == true;
        _saving = false;
      });
      ref.read(moodCategorizationStatusProvider.notifier).state = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mood AI settings saved')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Mood AI settings: $error')),
      );
    }
  }

  Future<void> _removeKey() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(moodCategorizationServiceProvider).setApiKey('');
      if (!mounted) return;
      setState(() {
        _hasKey = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenRouter API key removed')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove API key: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _keyController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: _hasKey ? 'Replace API key' : 'OpenRouter API key',
            helperText: _hasKey
                ? 'A key is stored securely on this device.'
                : 'Required to categorize songs. Get one from openrouter.ai/keys.',
            prefixIcon: const Icon(Icons.key_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Model ID',
            helperText: 'Default: google/gemma-4-31b-it:free',
            prefixIcon: Icon(Icons.smart_toy_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
            if (_hasKey) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Remove API key',
                onPressed: _saving ? null : _removeKey,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
