import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/login_screen.dart';
import '../ui/shell/main_shell.dart';
import '../ui/dashboard/dashboard.dart';
import '../ui/customers/customers.dart';
import '../ui/customers/customer_form.dart';
import '../ui/invoices/invoices.dart';
import '../ui/invoices/invoice_form.dart';
import '../ui/payments/payments.dart';
import '../ui/accounting/accounting.dart';
import '../ui/fleet/fleet.dart';
import '../ui/warehouse/warehouse.dart';
import '../ui/payroll/payroll.dart';
import '../ui/settings/settings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Auth guard handled by shell; login is always accessible
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const Dashboard()),
          GoRoute(path: '/customers', builder: (_, __) => const Customers()),
          GoRoute(path: '/customers/new', builder: (_, __) => const CustomerForm()),
          GoRoute(
            path: '/customers/:id',
            builder: (context, state) => CustomerForm(customerId: state.pathParameters['id']),
          ),
          GoRoute(path: '/invoices', builder: (_, __) => const Invoices()),
          GoRoute(path: '/invoices/new', builder: (_, __) => const InvoiceForm()),
          GoRoute(
            path: '/invoices/:id',
            builder: (context, state) => InvoiceForm(invoiceId: state.pathParameters['id']),
          ),
          GoRoute(path: '/payments', builder: (_, __) => const Payments()),
          GoRoute(path: '/accounting', builder: (_, __) => const Accounting()),
          GoRoute(path: '/fleet', builder: (_, __) => const Fleet()),
          GoRoute(path: '/warehouse', builder: (_, __) => const Warehouse()),
          GoRoute(path: '/payroll', builder: (_, __) => const Payroll()),
          GoRoute(path: '/settings', builder: (_, __) => const Settings()),
        ],
      ),
    ],
  );
});
