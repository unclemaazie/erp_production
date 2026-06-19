class Product {
  final String id;
  final String? sku;
  final String name;
  final String? description;
  final double unitPrice;
  final double costPrice;
  final String? category;
  final double taxRate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final DateTime? deletedAt;

  Product({
    required this.id,
    this.sku,
    required this.name,
    this.description,
    this.unitPrice = 0,
    this.costPrice = 0,
    this.category,
    this.taxRate = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'name': name,
        'description': description,
        'unit_price': unitPrice,
        'cost_price': costPrice,
        'category': category,
        'tax_rate': taxRate,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        sku: map['sku'] as String?,
        name: map['name'] as String,
        description: map['description'] as String?,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String?,
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
        isActive: map['is_active'] == 1,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
}

class InventoryItem {
  final String id;
  final String productId;
  final String warehouseId;
  final double quantityOnHand;
  final double quantityReserved;
  final double reorderLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.warehouseId,
    this.quantityOnHand = 0,
    this.quantityReserved = 0,
    this.reorderLevel = 0,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity_on_hand': quantityOnHand,
        'quantity_reserved': quantityReserved,
        'reorder_level': reorderLevel,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        warehouseId: map['warehouse_id'] as String,
        quantityOnHand: (map['quantity_on_hand'] as num?)?.toDouble() ?? 0,
        quantityReserved: (map['quantity_reserved'] as num?)?.toDouble() ?? 0,
        reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );
}
