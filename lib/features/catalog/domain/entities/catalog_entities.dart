import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.stock,
  });

  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String description;

  /// Integer rupiah, exactly as the backend stores it.
  final int price;
  final int stock;

  bool get inStock => stock > 0;

  @override
  List<Object?> get props => [id, categoryId, name, slug, description, price, stock];
}

class Category extends Equatable {
  const Category({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [id, name, slug];
}
