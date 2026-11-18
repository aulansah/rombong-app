import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the catalog is currently showing.
class CatalogFilter extends Equatable {
  const CatalogFilter({this.search = '', this.categoryId});

  final String search;

  /// null = "Semua" (all categories).
  final String? categoryId;

  @override
  List<Object?> get props => [search, categoryId];
}

/// How long typing must pause before a search request is sent.
/// A provider so tests can override it with Duration.zero.
final searchDebounceProvider = Provider<Duration>((ref) => const Duration(milliseconds: 400));

/// Holds the filter. The product list watches this provider, so any change
/// here reloads the list from page 1 automatically.
class CatalogFilterController extends Notifier<CatalogFilter> {
  Timer? _debounce;

  @override
  CatalogFilter build() {
    ref.onDispose(() => _debounce?.cancel());
    return const CatalogFilter();
  }

  /// Called on every keystroke. Without a debounce, typing "kopi arabika"
  /// would fire 12 requests; with it, only the final term is searched.
  void setSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(ref.read(searchDebounceProvider), () {
      final term = text.trim();
      if (term != state.search) state = CatalogFilter(search: term, categoryId: state.categoryId);
    });
  }

  void selectCategory(String? categoryId) {
    if (categoryId != state.categoryId) state = CatalogFilter(search: state.search, categoryId: categoryId);
  }
}

final catalogFilterProvider = NotifierProvider<CatalogFilterController, CatalogFilter>(CatalogFilterController.new);
