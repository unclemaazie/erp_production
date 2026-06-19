class Expense {
  final String id;
  final String? category;
  final double amount;
  final DateTime? expenseDate;
  final String? description;
  final String? receiptUrl;
  final String? approvedBy;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  Expense({
    required this.id,
    this.category,
    required this.amount,
    this.expenseDate,
    this.description,
    this.receiptUrl,
    this.approvedBy,
    this.status = 'pending',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate?.toIso8601String(),
        'description': description,
        'receipt_url': receiptUrl,
        'approved_by': approvedBy,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        category: map['category'] as String?,
        amount: (map['amount'] as num).toDouble(),
        expenseDate: map['expense_date'] != null ? DateTime.parse(map['expense_date'] as String) : null,
        description: map['description'] as String?,
        receiptUrl: map['receipt_url'] as String?,
        approvedBy: map['approved_by'] as String?,
        status: map['status'] as String? ?? 'pending',
        createdBy: map['created_by'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );
}
