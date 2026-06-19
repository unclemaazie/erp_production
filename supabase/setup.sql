-- ============================================================
-- ERP Production - Supabase Database Setup
-- Run this in the Supabase SQL Editor (new query)
-- ============================================================

-- ============================================================
-- 1. PROFILES (extends auth.users - auto-created via trigger)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  role TEXT DEFAULT 'readonly' CHECK (role IN ('admin', 'accountant', 'warehouse_manager', 'fleet_manager', 'salesperson', 'readonly')),
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  department TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 2. AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'role', 'readonly'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 3. COMPANY SETTINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.company_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  name TEXT DEFAULT 'My Company',
  logo_url TEXT,
  tax_number TEXT,
  address TEXT,
  default_currency TEXT DEFAULT 'ZAR',
  fiscal_year_end TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.company_settings (id, name) VALUES (1, 'My Company')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated read company settings" 
  ON public.company_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins update company settings" 
  ON public.company_settings FOR UPDATE TO authenticated 
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 4. CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  vat_number TEXT,
  billing_address TEXT,
  shipping_address TEXT,
  credit_limit NUMERIC DEFAULT 0,
  payment_terms INTEGER DEFAULT 30,
  is_active BOOLEAN DEFAULT TRUE,
  balance_due NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access customers" 
  ON public.customers FOR ALL TO authenticated USING (true);

-- ============================================================
-- 5. PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  unit_price NUMERIC DEFAULT 0,
  cost_price NUMERIC DEFAULT 0,
  category TEXT,
  tax_rate NUMERIC DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access products" 
  ON public.products FOR ALL TO authenticated USING (true);

-- ============================================================
-- 6. WAREHOUSES & INVENTORY
-- ============================================================
CREATE TABLE IF NOT EXISTS public.warehouses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  location TEXT,
  manager_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id),
  warehouse_id UUID REFERENCES public.warehouses(id),
  quantity_on_hand NUMERIC DEFAULT 0,
  quantity_reserved NUMERIC DEFAULT 0,
  reorder_level NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id),
  warehouse_id UUID REFERENCES public.warehouses(id),
  movement_type TEXT NOT NULL CHECK (movement_type IN ('inbound', 'outbound', 'adjustment', 'damage', 'recount')),
  quantity NUMERIC NOT NULL,
  reason TEXT,
  reference_id TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access warehouses" 
  ON public.warehouses FOR ALL TO authenticated USING (true);

ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access inventory" 
  ON public.inventory FOR ALL TO authenticated USING (true);

ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access stock_movements" 
  ON public.stock_movements FOR ALL TO authenticated USING (true);

-- ============================================================
-- 7. INVOICES & LINE ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE,
  customer_id UUID REFERENCES public.customers(id),
  customer_name TEXT,
  issue_date DATE,
  due_date DATE,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  subtotal NUMERIC DEFAULT 0,
  tax_total NUMERIC DEFAULT 0,
  total NUMERIC DEFAULT 0,
  amount_paid NUMERIC DEFAULT 0,
  balance_due NUMERIC DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.invoice_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id),
  description TEXT,
  quantity NUMERIC DEFAULT 1,
  unit_price NUMERIC DEFAULT 0,
  tax_rate NUMERIC DEFAULT 0,
  line_total NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access invoices" 
  ON public.invoices FOR ALL TO authenticated USING (true);

ALTER TABLE public.invoice_line_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access invoice_line_items" 
  ON public.invoice_line_items FOR ALL TO authenticated USING (true);

-- ============================================================
-- 8. PAYMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.customers(id),
  invoice_id UUID REFERENCES public.invoices(id),
  amount NUMERIC NOT NULL,
  method TEXT DEFAULT 'cash' CHECK (method IN ('cash', 'bank_transfer', 'card', 'cheque', 'other')),
  reference_number TEXT,
  payment_date DATE,
  notes TEXT,
  allocated BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access payments" 
  ON public.payments FOR ALL TO authenticated USING (true);

-- ============================================================
-- 9. FLEET
-- ============================================================
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration TEXT UNIQUE NOT NULL,
  make TEXT,
  model TEXT,
  year INTEGER,
  vin TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'retired')),
  assigned_driver_id UUID REFERENCES public.profiles(id),
  current_odometer NUMERIC DEFAULT 0,
  fuel_type TEXT CHECK (fuel_type IN ('diesel', 'petrol', 'electric', 'hybrid')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.fleet_maintenance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES public.vehicles(id),
  service_date DATE,
  next_service_due DATE,
  cost NUMERIC DEFAULT 0,
  description TEXT,
  service_type TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.fleet_trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID REFERENCES public.vehicles(id),
  driver_id UUID REFERENCES public.profiles(id),
  start_location TEXT,
  end_location TEXT,
  start_odometer NUMERIC,
  end_odometer NUMERIC,
  distance NUMERIC,
  purpose TEXT,
  fuel_cost NUMERIC DEFAULT 0,
  trip_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access vehicles" 
  ON public.vehicles FOR ALL TO authenticated USING (true);

ALTER TABLE public.fleet_maintenance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access fleet_maintenance" 
  ON public.fleet_maintenance FOR ALL TO authenticated USING (true);

ALTER TABLE public.fleet_trips ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access fleet_trips" 
  ON public.fleet_trips FOR ALL TO authenticated USING (true);

-- ============================================================
-- 10. PAYROLL
-- ============================================================
CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id),
  employee_number TEXT UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  department TEXT,
  job_title TEXT,
  salary NUMERIC,
  hourly_rate NUMERIC,
  start_date DATE,
  bank_details TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.payroll_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_start DATE,
  period_end DATE,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'processing', 'completed')),
  total_gross NUMERIC DEFAULT 0,
  total_deductions NUMERIC DEFAULT 0,
  total_net NUMERIC DEFAULT 0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payslips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES public.employees(id),
  payroll_run_id UUID REFERENCES public.payroll_runs(id),
  hours_worked NUMERIC DEFAULT 0,
  gross_pay NUMERIC DEFAULT 0,
  tax NUMERIC DEFAULT 0,
  deductions NUMERIC DEFAULT 0,
  net_pay NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access employees" 
  ON public.employees FOR ALL TO authenticated USING (true);

ALTER TABLE public.payroll_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access payroll_runs" 
  ON public.payroll_runs FOR ALL TO authenticated USING (true);

ALTER TABLE public.payslips ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access payslips" 
  ON public.payslips FOR ALL TO authenticated USING (true);

-- ============================================================
-- 11. ACCOUNTING
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
  parent_id UUID REFERENCES public.chart_of_accounts(id),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_date DATE,
  reference TEXT,
  description TEXT,
  debit_account_id UUID REFERENCES public.chart_of_accounts(id),
  credit_account_id UUID REFERENCES public.chart_of_accounts(id),
  amount NUMERIC NOT NULL,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT,
  amount NUMERIC NOT NULL,
  expense_date DATE,
  description TEXT,
  receipt_url TEXT,
  approved_by UUID REFERENCES public.profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access chart_of_accounts" 
  ON public.chart_of_accounts FOR ALL TO authenticated USING (true);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access journal_entries" 
  ON public.journal_entries FOR ALL TO authenticated USING (true);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access expenses" 
  ON public.expenses FOR ALL TO authenticated USING (true);

-- ============================================================
-- 12. REALTIME
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.customers, public.products, public.invoices, public.payments, public.vehicles, public.employees, public.expenses, public.inventory;

-- ============================================================
-- 13. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_customers_name ON public.customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON public.invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON public.payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON public.inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_registration ON public.vehicles(registration);
CREATE INDEX IF NOT EXISTS idx_employees_number ON public.employees(employee_number);

-- ============================================================
-- 14. DEFAULT CHART OF ACCOUNTS
-- ============================================================
INSERT INTO public.chart_of_accounts (code, name, account_type) VALUES
('1000', 'Cash & Bank', 'asset'),
('1100', 'Accounts Receivable', 'asset'),
('1200', 'Inventory', 'asset'),
('2000', 'Accounts Payable', 'liability'),
('2100', 'VAT Payable', 'liability'),
('3000', 'Owner Equity', 'equity'),
('4000', 'Sales Revenue', 'revenue'),
('5000', 'Cost of Goods Sold', 'expense'),
('5100', 'Salaries & Wages', 'expense'),
('5200', 'Rent Expense', 'expense'),
('5300', 'Utilities', 'expense'),
('5400', 'Fuel & Transport', 'expense'),
('5500', 'Maintenance', 'expense')
ON CONFLICT (code) DO NOTHING;
