import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        table_name TEXT PRIMARY KEY,
        last_sync_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        record_id TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        retry_count INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT,
        role TEXT DEFAULT 'readonly',
        full_name TEXT,
        phone TEXT,
        avatar_url TEXT,
        department TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT,
        logo_url TEXT,
        tax_number TEXT,
        address TEXT,
        default_currency TEXT DEFAULT 'ZAR',
        fiscal_year_end TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        vat_number TEXT,
        billing_address TEXT,
        shipping_address TEXT,
        credit_limit REAL DEFAULT 0,
        payment_terms INTEGER DEFAULT 30,
        is_active INTEGER DEFAULT 1,
        balance_due REAL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_contacts (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        name TEXT,
        email TEXT,
        phone TEXT,
        role TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        sku TEXT UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        unit_price REAL DEFAULT 0,
        cost_price REAL DEFAULT 0,
        category TEXT,
        tax_rate REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT,
        manager_id TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        quantity_on_hand REAL DEFAULT 0,
        quantity_reserved REAL DEFAULT 0,
        reorder_level REAL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reason TEXT,
        reference_id TEXT,
        created_by TEXT,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT UNIQUE,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        issue_date TEXT,
        due_date TEXT,
        status TEXT DEFAULT 'draft',
        subtotal REAL DEFAULT 0,
        tax_total REAL DEFAULT 0,
        total REAL DEFAULT 0,
        amount_paid REAL DEFAULT 0,
        balance_due REAL DEFAULT 0,
        notes TEXT,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_line_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT,
        description TEXT,
        quantity REAL DEFAULT 1,
        unit_price REAL DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        line_total REAL DEFAULT 0,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT,
        invoice_id TEXT,
        amount REAL NOT NULL,
        method TEXT DEFAULT 'cash',
        reference_number TEXT,
        payment_date TEXT,
        notes TEXT,
        allocated INTEGER DEFAULT 0,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicles (
        id TEXT PRIMARY KEY,
        registration TEXT UNIQUE NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        vin TEXT,
        status TEXT DEFAULT 'active',
        assigned_driver_id TEXT,
        current_odometer REAL DEFAULT 0,
        fuel_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fleet_maintenance (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        service_date TEXT,
        next_service_due TEXT,
        cost REAL DEFAULT 0,
        description TEXT,
        service_type TEXT,
        created_by TEXT,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fleet_trips (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        driver_id TEXT,
        start_location TEXT,
        end_location TEXT,
        start_odometer REAL,
        end_odometer REAL,
        distance REAL,
        purpose TEXT,
        fuel_cost REAL DEFAULT 0,
        trip_date TEXT,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        employee_number TEXT UNIQUE,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        department TEXT,
        job_title TEXT,
        salary REAL,
        hourly_rate REAL,
        start_date TEXT,
        bank_details TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payroll_runs (
        id TEXT PRIMARY KEY,
        period_start TEXT,
        period_end TEXT,
        status TEXT DEFAULT 'draft',
        total_gross REAL DEFAULT 0,
        total_deductions REAL DEFAULT 0,
        total_net REAL DEFAULT 0,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payslips (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        payroll_run_id TEXT NOT NULL,
        hours_worked REAL DEFAULT 0,
        gross_pay REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        deductions REAL DEFAULT 0,
        net_pay REAL DEFAULT 0,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chart_of_accounts (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        parent_id TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        entry_date TEXT,
        reference TEXT,
        description TEXT,
        debit_account_id TEXT,
        credit_account_id TEXT,
        amount REAL NOT NULL,
        created_by TEXT,
        created_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        category TEXT,
        amount REAL NOT NULL,
        expense_date TEXT,
        description TEXT,
        receipt_url TEXT,
        approved_by TEXT,
        status TEXT DEFAULT 'pending',
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_outbox_synced ON outbox(synced);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory(product_id);
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id);
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future versions
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> reset() async {
    await close();
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    await deleteDatabase(path);
  }
}
