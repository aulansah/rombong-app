import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase.dart';
import '../../catalog_providers.dart';
import '../../domain/entities/catalog_entities.dart';

/// Read-only data with no user actions attached: a FutureProvider is enough.
/// A Failure is thrown so the UI receives it as AsyncError.

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.watch(getCategoriesUseCaseProvider)(const NoParams());
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// `family`: one cached entry per product ID. `autoDispose`: dropped when the
/// detail screen closes, so reopening it shows fresh stock.
final productDetailProvider = FutureProvider.autoDispose.family<Product, String>((ref, id) async {
  final result = await ref.watch(getProductDetailUseCaseProvider)(id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});
