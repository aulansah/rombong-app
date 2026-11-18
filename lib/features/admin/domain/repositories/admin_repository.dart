import '../../../../core/result.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../orders/domain/entities/order.dart';
import '../entities/product_draft.dart';

/// Admin-only writes. The backend checks the admin role on every call; the
/// app hiding the screens is only convenience, not security.
abstract interface class AdminRepository {
  Future<Result<Product>> createProduct(ProductDraft draft);
  Future<Result<Product>> updateProduct(String id, ProductDraft draft);
  Future<Result<Product>> updateStock(String id, int stock);
  Future<Result<void>> deleteProduct(String id);

  Future<Result<Category>> createCategory(String name);
  Future<Result<Category>> renameCategory(String id, String name);
  Future<Result<void>> deleteCategory(String id);

  Future<Result<Order>> updateOrderStatus(String orderId, OrderStatus status);
}
