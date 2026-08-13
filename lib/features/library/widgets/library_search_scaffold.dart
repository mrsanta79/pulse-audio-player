import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/search_filter.dart';
import '../../../widgets/search_field.dart';

/// Page shell for the library sub-pages (artists, albums, years, songs).
///
/// Each of those pages already holds its whole list in memory, so the search
/// here is a plain filter over that list rather than another database query:
/// no debounce, no loading state, results update on the keystroke.
///
/// The field is revealed from the app bar instead of sitting above the list
/// permanently, so browsing a library that fits on screen costs no space.
class LibrarySearchScaffold<T> extends StatefulWidget {
  const LibrarySearchScaffold({
    super.key,
    required this.title,
    required this.items,
    required this.searchText,
    required this.builder,
    required this.hintText,
    this.actions,
    this.noMatchesMessage = 'No matches',
  });

  final String title;
  final List<T> items;

  /// The text a row is matched against. Join every field worth searching,
  /// e.g. a song's title, artist and album.
  final String Function(T item) searchText;

  /// Builds the list/grid for the items that survived the filter.
  final Widget Function(BuildContext context, List<T> filtered) builder;

  final String hintText;

  /// Extra app bar actions, given the filtered items so that a bulk action
  /// (shuffle, say) applies to what the user is actually looking at.
  final List<Widget> Function(List<T> filtered)? actions;

  final String noMatchesMessage;

  @override
  State<LibrarySearchScaffold<T>> createState() =>
      _LibrarySearchScaffoldState<T>();
}

class _LibrarySearchScaffoldState<T> extends State<LibrarySearchScaffold<T>> {
  bool _searching = false;
  String _query = '';

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      // Closing drops the query: the field itself is disposed with it, so
      // leaving a stale filter behind would hide rows with nothing on screen
      // to explain why.
      if (!_searching) _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final filtered = filterBySearchQuery(
      widget.items,
      _query,
      widget.searchText,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ...?widget.actions?.call(filtered),
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _searching ? 'Close search' : 'Search ${widget.title}',
          ),
        ],
      ),
      // Sides only: the app bar already clears the status bar, and the lists
      // end with `bottomGap` so they clear the floating nav. What is left is
      // the gesture bar, which sits on a side edge in landscape and would
      // otherwise cut into the content.
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (_searching)
              SearchField(
                autofocus: true,
                hintText: widget.hintText,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            Expanded(
              child: filtered.isEmpty && _query.isNotEmpty
                  ? Center(
                      child: Text(
                        widget.noMatchesMessage,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : widget.builder(context, filtered),
            ),
          ],
        ),
      ),
    );
  }
}
