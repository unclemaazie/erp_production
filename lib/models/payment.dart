class Payment {
  final String id;
  final String? customerId;
  final String? invoiceId;
  final double amount;
  final String method;
  final String? referenceNumber;
  final DateTime? paymentDate;
  final String? notes;
  final int allocated;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  Payment({
    required this.id,
    this.customerId,
    this.invoiceId,
    required this.amount,
    this.method = 'cash',
    this.referenceNumber,
    this.paymentDate,
    this.notes,
    this.allocated = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'invoice_id': invoiceId,
        'amount': amount,
        'method': method,
        'reference_number': referenceNumber,
        'payment_date': paymentDate?.toIso8601String(),
        'notes': notes,
        'allocated': allocated,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        customerId: map['customer_id'] as String?,
        invoiceId: map['invoice_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        method: map['method'] as String? ?? 'cash',
        referenceNumber: map['reference_number'] as String?,
        paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date'] as String) : null,
        notes: map['notes'] as String?,
        allocated: map['allocated'] as int? ?? 0,
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );
}
