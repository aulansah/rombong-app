import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/pagination.dart';
import '../../../../core/result.dart';
import '../../catalog_providers.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'catalog_filter_controller.dart';

/// Everything the product grid needs: the items loaded so far plus the
/// pagination bookkeeping for infinite scroll.
class ProductListState extends Equatable {
  const ProductListState({
    required this.filter,
    this.items = const [],
    this.page = 0,
    this.totalPages = 0,
    this.totalItems = 0,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// The filter these items belong to; used to drop stale page responses.
  final CatalogFilter filter;
  final List<Product> items;
  final int page;
  final int totalPages;
  final int totalItems;
  final bool isLoadingMore;

  /// A failed "next page" request. The items already shown stay visible.
  final Failure? loadMoreError;

  bool get hasMore => page < totalPages;

  ProductListState copyWith({
    List<Product>? items,
    int? page,
    int? totalPages,
    int? totalItems,
    bool? isLoadingMore,
    Failure? loadMoreError,
    bool clearError = false,
  }) {
    return ProductListState(
      filter: filter,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [filter, items, page, totalPages, totalItems, isLoadingMore, loadMoreError];
}

/// Paginated product list.
///
/// - `build()` loads page 1 and re-runs whenever the filter changes
///   (it `ref.watch`es [catalogFilterProvider]).
/// - `loadMore()` appends the next page; called by the grid near the bottom.
///
/// The first page failing turns the whole provider into AsyncError (full
/// error screen). A later page failing only sets [ProductListState.loadMoreError]
/// so the products already on screen are kept.
class ProductListController extends AsyncNotifier<ProductListState> {
  static const pageSize = 20;

  @override
  Future<ProductListState> build() async {
    final filter = ref.watch(catalogFilterProvider);
    final first = await _fetch(filter, 1);
    return ProductListState(
      filter: filter,
      items: first.items,
      page: first.page,
      totalPages: first.totalPages,
      totalItems: first.totalItems,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    // Ignore when: nothing loaded yet, a reload is running, a page is already
    // on its way (scroll events fire many times), or there is nothing left.
    if (current == null || state.isLoading || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    final result = await ref.read(getProductsUseCaseProvider)(ProductQuery(
      page: current.page + 1,
      limit: pageSize,
      search: current.filter.search,
      categoryId: current.filter.categoryId,
    ));

    // The filter may have changed while this page was loading: that rebuild
    // owns the state now, so this (stale) response is dropped.
    final latest = state.value;
    if (!ref.mounted || state.isLoading || latest == null || latest.filter != current.filter) return;

    state = AsyncData(switch (result) {
      Ok(:final value) => latest.copyWith(
          items: [...latest.items, ...value.items],
          page: value.page,
          totalPages: value.totalPages,
          totalItems: value.totalItems,
          isLoadingMore: false,
        ),
      Err(:final failure) => latest.copyWith(isLoadingMore: false, loadMoreError: failure),
    });
  }

  Future<Paged<Product>> _fetch(CatalogFilter filter, int page) async {
    final result = await ref.read(getProductsUseCaseProvider)(ProductQuery(
      page: page,
      limit: pageSize,
      search: filter.search,
      categoryId: filter.categoryId,
    ));
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final productListControllerProvider =
    AsyncNotifierProvider<ProductListController, ProductListState>(ProductListController.new);
