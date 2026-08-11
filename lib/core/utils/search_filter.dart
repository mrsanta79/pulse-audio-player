/// Filters a list the user is already looking at, in memory.
///
/// Every whitespace-separated term in [query] has to appear somewhere in an
/// item's [searchText], case-insensitively and in any order, so "cure the"
/// still finds "The Cure". An empty query keeps the list as it is.
///
/// This is for lists a screen already holds; full-library search goes through
/// the database instead (see `searchLibrary`).
List<T> filterBySearchQuery<T>(
  List<T> items,
  String query,
  String Function(T item) searchText,
) {
  final terms = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((term) => term.isEmpty);
  if (terms.isEmpty) return items;

  return items.where((item) {
    final haystack = searchText(item).toLowerCase();
    return terms.every(haystack.contains);
  }).toList();
}
