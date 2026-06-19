class AppConstants {
  static const String appName = 'ERP Production';
  static const String version = '1.0.0';
  static const String dbName = 'erp_production.db';
  static const int dbVersion = 1;
  static const String outboxTable = 'outbox';
  static const String syncMetaTable = 'sync_metadata';
}

class AppRoles {
  static const String admin = 'admin';
  static const String accountant = 'accountant';
  static const String warehouseManager = 'warehouse_manager';
  static const String fleetManager = 'fleet_manager';
  static const String salesperson = 'salesperson';
  static const String readonly = 'readonly';
}

class SyncStatus {
  static const int pending = 0;
  static const int synced = 1;
  static const int conflict = 2;
  static const int error = 3;
}

class InvoiceStatus {
  static const String draft = 'draft';
  static const String sent = 'sent';
  static const String paid = 'paid';
  static const String overdue = 'overdue';
  static const String cancelled = 'cancelled';
}

class PaymentMethod {
  static const String cash = 'cash';
  static const String bankTransfer = 'bank_transfer';
  static const String card = 'card';
  static const String cheque = 'cheque';
  static const String other = 'other';
}
