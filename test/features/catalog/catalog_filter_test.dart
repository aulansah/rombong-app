import 'package:ecommerce_app/features/catalog/presentation/controllers/catalog_filter_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search is debounced: only the last term is applied', () async {
    final container = ProviderContainer.test(overrides: [
      searchDebounceProvider.overrideWithValue(const Duration(milliseconds: 50)),
    ]);
    final applied = <String>[];
    container.listen(catalogFilterProvider, (previous, next) => applied.add(next.search));
    final filter = container.read(catalogFilterProvider.notifier);

    for (final term in ['k', 'ko', 'kop', 'kopi']) {
      filter.setSearch(term);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(applied, isEmpty, reason: 'still typing');

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(applied, ['kopi']);
  });

  test('whitespace-only changes do not trigger a new search', () async {
    final container = ProviderContainer.test(overrides: [
      searchDebounceProvider.overrideWithValue(Duration.zero),
    ]);
    var changes = 0;
    container.listen(catalogFilterProvider, (previous, next) => changes++);
    final filter = container.read(catalogFilterProvider.notifier);

    filter.setSearch('kopi');
    await Future<void>.delayed(Duration.zero);
    filter.setSearch('  kopi  ');
    await Future<void>.delayed(Duration.zero);

    expect(changes, 1);
  });

  test('selecting a category keeps the search term', () async {
    final container = ProviderContainer.test(overrides: [
      searchDebounceProvider.overrideWithValue(Duration.zero),
    ]);
    final filter = container.read(catalogFilterProvider.notifier);

    filter.setSearch('kopi');
    await Future<void>.delayed(Duration.zero);
    filter.selectCategory('c1');

    expect(container.read(catalogFilterProvider), const CatalogFilter(search: 'kopi', categoryId: 'c1'));

    filter.selectCategory(null);
    expect(container.read(catalogFilterProvider).categoryId, isNull);
  });
}
