import 'package:equatable/equatable.dart';

/// Input of the product form (create or edit). Money is an int in rupiah,
/// like everywhere else in the app.
class ProductDraft extends Equatable {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
  });

  final String name;
  final String description;
  final int price;
  final int stock;
  final String categoryId;

  ProductDraft trimmed() => ProductDraft(
        name: name.trim(),
        description: description.trim(),
        price: price,
        stock: stock,
        categoryId: categoryId,
      );

  @override
  List<Object?> get props => [name, description, price, stock, categoryId];
}
