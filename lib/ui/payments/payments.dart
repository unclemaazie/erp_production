import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/payment.dart';
import '../../models/invoice.dart';
import 'payment_form.dart';

class Payments extends ConsumerStatefulWidget {
  const Payments({super.key});

  @override
  ConsumerState<Payments> createState() => _PaymentsState();
}

class _PaymentsState extends ConsumerState<Payments> {
  late Future<List<Payment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Payment>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.query('payments', orderBy: 'payment_date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => PaymentFormDialog(onSaved: _refresh),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Payment>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text('No payments recorded', style: TextStyle(color: AppTheme.textSecondary)));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.success.withOpacity(0.2),
                  child: const Icon(Icons.payments, color: AppTheme.success, size: 18),
                ),
                title: Text('R ${p.amount.toStringAsFixed(2)}'),
                subtitle: Text('${p.method.toUpperCase()} • ${p.paymentDate?.toIso8601String().split('T').first ?? 'No date'}'),
                trailing: p.allocated == 1
                    ? const Chip(label: Text('ALLOCATED'), backgroundColor: AppTheme.success, labelStyle: TextStyle(color: Colors.white, fontSize: 10))
                    : const Chip(label: Text('UNALLOCATED'), backgroundColor: AppTheme.warning, labelStyle: TextStyle(color: Colors.white, fontSize: 10)),
              );
            },
          );
        },
      ),
    );
  }
}
