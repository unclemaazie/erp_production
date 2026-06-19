class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? vatNumber;
  final String? billingAddress;
  final String? shippingAddress;
  final double creditLimit;
  final int paymentTerms;
  final bool isActive;
  final double balanceDue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final DateTime? deletedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.vatNumber,
    this.billingAddress,
    this.shippingAddress,
    this.creditLimit = 0,
    this.paymentTerms = 30,
    this.isActive = true,
    this.balanceDue = 0,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'vat_number': vatNumber,
        'billing_address': billingAddress,
        'shipping_address': shippingAddress,
        'credit_limit': creditLimit,
        'payment_terms': paymentTerms,
        'is_active': isActive ? 1 : 0,
        'balance_due': balanceDue,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        vatNumber: map['vat_number'] as String?,
        billingAddress: map['billing_address'] as String?,
        shippingAddress: map['shipping_address'] as String?,
        creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0,
        paymentTerms: map['payment_terms'] as int? ?? 30,
        isActive: map['is_active'] == 1,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? vatNumber,
    String? billingAddress,
    String? shippingAddress,
    double? creditLimit,
    int? paymentTerms,
    bool? isActive,
    double? balanceDue,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    DateTime? deletedAt,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        vatNumber: vatNumber ?? this.vatNumber,
        billingAddress: billingAddress ?? this.billingAddress,
        shippingAddress: shippingAddress ?? this.shippingAddress,
        creditLimit: creditLimit ?? this.creditLimit,
        paymentTerms: paymentTerms ?? this.paymentTerms,
        isActive: isActive ?? this.isActive,
        balanceDue: balanceDue ?? this.balanceDue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
