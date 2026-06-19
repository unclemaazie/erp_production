class Invoice {
  final String id;
  final String? invoiceNumber;
  final String customerId;
  final String? customerName;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String status;
  final double subtotal;
  final double taxTotal;
  final double total;
  final double amountPaid;
  final double balanceDue;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final DateTime? deletedAt;

  Invoice({
    required this.id,
    this.invoiceNumber,
    required this.customerId,
    this.customerName,
    this.issueDate,
    this.dueDate,
    this.status = 'draft',
    this.subtotal = 0,
    this.taxTotal = 0,
    this.total = 0,
    this.amountPaid = 0,
    this.balanceDue = 0,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'issue_date': issueDate?.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'status': status,
        'subtotal': subtotal,
        'tax_total': taxTotal,
        'total': total,
        'amount_paid': amountPaid,
        'balance_due': balanceDue,
        'notes': notes,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
        id: map['id'] as String,
        invoiceNumber: map['invoice_number'] as String?,
        customerId: map['customer_id'] as String,
        customerName: map['customer_name'] as String?,
        issueDate: map['issue_date'] != null ? DateTime.parse(map['issue_date'] as String) : null,
        dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
        status: map['status'] as String? ?? 'draft',
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        taxTotal: (map['tax_total'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String?,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    DateTime? issueDate,
    DateTime? dueDate,
    String? status,
    double? subtotal,
    double? taxTotal,
    double? total,
    double? amountPaid,
    double? balanceDue,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    DateTime? deletedAt,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        issueDate: issueDate ?? this.issueDate,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        subtotal: subtotal ?? this.subtotal,
        taxTotal: taxTotal ?? this.taxTotal,
        total: total ?? this.total,
        amountPaid: amountPaid ?? this.amountPaid,
        balanceDue: balanceDue ?? this.balanceDue,
        notes: notes ?? this.notes,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}

class InvoiceLineItem {
  final String id;
  final String invoiceId;
  final String? productId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double lineTotal;
  final DateTime? createdAt;
  final int syncStatus;

  InvoiceLineItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.lineTotal = 0,
    this.createdAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'product_id': productId,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'tax_rate': taxRate,
        'line_total': lineTotal,
        'created_at': createdAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) => InvoiceLineItem(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        productId: map['product_id'] as String?,
        description: map['description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
        lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );
}
