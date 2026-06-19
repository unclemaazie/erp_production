import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/db/local_db.dart';
import '../../models/invoice.dart';

class Invoices extends ConsumerStatefulWidget {
  const Invoices({super.key});

  @override
  ConsumerState<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends ConsumerState<Invoices> {
  late Future<List<Invoice>> _future;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Invoice>> _load() async {
    final db = await LocalDB.instance;
    if (_statusFilter == null) {
      final rows = await db.query('invoices', where: 'deleted_at IS NULL', orderBy: 'issue_date DESC');
      return rows.map(Invoice.fromMap).toList();
    }
    final rows = await db.query(
      'invoices',
      where: 'deleted_at IS NULL AND status = ?',
      whereArgs: [_statusFilter],
      orderBy: 'issue_date DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  void _refresh() => setState(() => _future = _load());

  Color _statusColor(String status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppTheme.success;
      case InvoiceStatus.overdue:
        return AppTheme.danger;
      case InvoiceStatus.sent:
        return AppTheme.primary;
      case InvoiceStatus.draft:
        return AppTheme.textSecondary;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              _statusFilter = v;
              _refresh();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: InvoiceStatus.draft, child: Text('Draft')),
              const PopupMenuItem(value: InvoiceStatus.sent, child: Text('Sent')),
              const PopupMenuItem(value: InvoiceStatus.paid, child: Text('Paid')),
              const PopupMenuItem(value: InvoiceStatus.overdue, child: Text('Overdue')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/invoices/new'),
          ),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text('No invoices', style: TextStyle(color: AppTheme.textSecondary)));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final inv = list[i];
              return ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  color: _statusColor(inv.status),
                ),
                title: Text(inv.invoiceNumber ?? 'Draft'),
                subtitle: Text('${inv.customerName ?? 'Unknown'} • R ${inv.total.toStringAsFixed(2)}'),
                trailing: Chip(
                  label: Text(inv.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: _statusColor(inv.status).withOpacity(0.15),
                  side: BorderSide.none,
                  labelStyle: TextStyle(color: _statusColor(inv.status), fontWeight: FontWeight.w600),
                ),
                onTap: () => context.push('/invoices/${inv.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
