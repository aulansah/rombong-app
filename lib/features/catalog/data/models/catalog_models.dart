import '../../domain/entities/catalog_entities.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.slug,
    required super.description,
    required super.price,
    required super.stock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toInt(),
        stock: (json['stock'] as num).toInt(),
      );
}

class CategoryModel extends Category {
  const CategoryModel({required super.id, required super.name, required super.slug});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}
