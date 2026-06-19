import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/invoice.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  late Future<Map<String, dynamic>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final db = await LocalDB.instance;

    final invoices = await db.query('invoices', where: 'deleted_at IS NULL');
    final customers = await db.query('customers', where: 'deleted_at IS NULL');
    final vehicles = await db.query('vehicles', where: 'deleted_at IS NULL AND status = ?', whereArgs: ['active']);
    final products = await db.query('products', where: 'deleted_at IS NULL');

    double totalRevenue = 0;
    double totalPaid = 0;
    int overdueCount = 0;
    for (final r in invoices) {
      final inv = Invoice.fromMap(r);
      totalRevenue += inv.total;
      totalPaid += inv.amountPaid;
      if (inv.status == 'overdue' || (inv.dueDate != null && inv.dueDate!.isBefore(DateTime.now()) && inv.status != 'paid')) {
        overdueCount++;
      }
    }

    return {
      'revenue': totalRevenue,
      'paid': totalPaid,
      'balance': totalRevenue - totalPaid,
      'invoices': invoices.length,
      'overdue': overdueCount,
      'customers': customers.length,
      'fleet': vehicles.length,
      'products': products.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _stats,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard('Revenue', 'R ${s['revenue'].toStringAsFixed(2)}', AppTheme.success),
                _KpiCard('Paid', 'R ${s['paid'].toStringAsFixed(2)}', AppTheme.primary),
                _KpiCard('Balance Due', 'R ${s['balance'].toStringAsFixed(2)}', AppTheme.warning),
                _KpiCard('Invoices', '${s['invoices']}', AppTheme.accent),
                _KpiCard('Overdue', '${s['overdue']}', AppTheme.danger),
                _KpiCard('Customers', '${s['customers']}', AppTheme.textSecondary),
                _KpiCard('Fleet Active', '${s['fleet']}', AppTheme.textSecondary),
                _KpiCard('Products', '${s['products']}', AppTheme.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  const _KpiCard(this.title, this.value, this.accent);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
