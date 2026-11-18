import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/features/catalog/domain/entities/catalog_entities.dart';
import 'package:ecommerce_app/features/catalog/presentation/widgets/catalog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: SizedBox(width: 156, height: 236, child: child))),
    );

const _product = Product(
  id: 'p1',
  categoryId: 'c1',
  name: 'Kopi Arabika Gayo 250g',
  slug: 'kopi',
  description: '',
  price: 85000,
  stock: 10,
);

void main() {
  testWidgets('ProductCard shows name, formatted price and stock', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(ProductCard(product: _product, onTap: () => taps++)));

    expect(find.text('Kopi Arabika Gayo 250g'), findsOneWidget);
    expect(find.text('Rp85.000'), findsOneWidget);
    expect(find.text('Stok 10'), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(taps, 1);
  });

  testWidgets('ProductCard shows the sold-out variant', (tester) async {
    const soldOut = Product(
      id: 'p2', categoryId: 'c1', name: 'Teh Hijau', slug: 'teh', description: '', price: 30000, stock: 0,
    );
    await tester.pumpWidget(_wrap(ProductCard(product: soldOut, onTap: () {})));

    expect(find.text('Stok habis'), findsOneWidget);
  });

  testWidgets('CategoryChip reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(CategoryChip(label: 'Minuman', selected: false, onTap: () => taps++)));

    await tester.tap(find.text('Minuman'));
    expect(taps, 1);
  });
}
