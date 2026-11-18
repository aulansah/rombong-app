import 'package:equatable/equatable.dart';

/// One page of a list endpoint, built from the backend's
/// `meta: { page, limit, total_items, total_pages }`.
class Paged<T> extends Equatable {
  const Paged({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalItems;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, totalPages, totalItems];
}
