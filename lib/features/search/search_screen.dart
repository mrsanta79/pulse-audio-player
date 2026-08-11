import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/search_field.dart';
import 'search_results.dart';
import 'widgets/search_filter_chips.dart';
import 'widgets/search_results_list.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _debounceDelay = Duration(milliseconds: 250);

  Timer? _debounce;
  SearchFilter _filter = SearchFilter.songs;
  String _query = '';
  SearchResults _results = SearchResults.empty;

  /// Identifies the most recent search, so a slow query that finishes after a
  /// newer one can't overwrite the newer results.
  int _searchId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    final id = ++_searchId;
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _query = '';
          _results = SearchResults.empty;
        });
      }
      return;
    }

    // Albums and artists come from the providers the Library tab already keeps
    // warm, rather than re-running a GROUP BY over every track per keystroke.
    // Awaited rather than read off the current value: on the first search of a
    // session they may not have resolved yet, and dropping them would report
    // "no results" for a library that has them.
    final results = await searchLibrary(
      query,
      tracks: ref.read(databaseProvider).searchTracks(query),
      albums: await ref.read(albumsProvider.future),
      artists: await ref.read(artistsProvider.future),
    );

    if (!mounted || id != _searchId) return;
    setState(() {
      _query = query;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            SearchField(onChanged: _onQueryChanged),
            SearchFilterChips(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SearchResultsList(
                query: _query,
                filter: _filter,
                results: _results,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
