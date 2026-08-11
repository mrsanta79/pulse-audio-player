import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The app's one search input: the Search tab's field, and the field the
/// library sub-pages reveal from their app bar.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search songs, albums, artists',
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        12,
        AppSpacing.pageH,
        8,
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: palette.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: palette.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: palette.textSecondary),
          filled: true,
          fillColor: palette.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
