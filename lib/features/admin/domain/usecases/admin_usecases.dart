import '../../../../core/error/failure.dart';
import '../../../../core/result.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/product_draft.dart';
import '../repositories/admin_repository.dart';

/// Only operations with rules of their own get a use case. Simple deletes
/// and renames go straight to the repository: a use case that only
/// forwards the call adds a file without adding meaning.

/// Creates or updates a product after checking the same rules as the
/// backend validator, so the form can show the error without a request.
class SaveProduct {
  const SaveProduct(this._repository);
  final AdminRepository _repository;

  /// [id] null → create, otherwise update.
  Future<Result<Product>> call(ProductDraft input, {String? id}) async {
    final draft = input.trimmed();
    final problems = <String, String>{
      if (draft.name.length < 3) 'name': 'Minimal 3 karakter',
      if (draft.name.length > 200) 'name': 'Maksimal 200 karakter',
      if (draft.description.length > 5000) 'description': 'Maksimal 5000 karakter',
      if (draft.price <= 0) 'price': 'Harga harus lebih dari 0',
      if (draft.stock < 0) 'stock': 'Stok tidak boleh negatif',
      if (draft.categoryId.isEmpty) 'category_id': 'Pilih kategori',
    };
    if (problems.isNotEmpty) {
      return Err(ServerFailure('Periksa kembali isian produk.', statusCode: 422, fieldErrors: problems));
    }
    return id == null ? _repository.createProduct(draft) : _repository.updateProduct(id, draft);
  }
}

/// Moves an order to the next fulfilment step. Allowed steps mirror the
/// backend's transition table; cancelling uses the cancel endpoint.
class AdvanceOrder {
  const AdvanceOrder(this._repository);
  final AdminRepository _repository;

  Future<Result<Order>> call(Order order) async {
    final next = order.status.nextForAdmin;
    if (next == null) {
      return Err(ServerFailure('Status ${order.status.name} tidak bisa diubah lagi.', statusCode: 409));
    }
    return _repository.updateOrderStatus(order.id, next);
  }
}
