import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/expense.dart';
import 'expense_form.dart';

class Accounting extends ConsumerStatefulWidget {
  const Accounting({super.key});

  @override
  ConsumerState<Accounting> createState() => _AccountingState();
}

class _AccountingState extends ConsumerState<Accounting> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tab = i),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Journal'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _ExpensesTab(),
          _JournalTab(),
          _ReportsTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ExpenseFormDialog(onSaved: () => setState(() {})),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Expense>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No expenses', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            Color statusColor = AppTheme.warning;
            if (e.status == 'approved') statusColor = AppTheme.success;
            if (e.status == 'rejected') statusColor = AppTheme.danger;
            return ListTile(
              leading: Container(
                width: 4,
                height: 40,
                color: statusColor,
              ),
              title: Text(e.description ?? 'Expense'),
              subtitle: Text('${e.category ?? 'Uncategorized'} • ${e.expenseDate?.toIso8601String().split('T').first ?? ''}'),
              trailing: Text('R ${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            );
          },
        );
      },
    );
  }

  Future<List<Expense>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.query('expenses', orderBy: 'expense_date DESC');
    return rows.map(Expense.fromMap).toList();
  }
}

class _JournalTab extends StatelessWidget {
  const _JournalTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Journal Entries - Coming Soon', style: TextStyle(color: AppTheme.textSecondary)));
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Financial Reports - Coming Soon', style: TextStyle(color: AppTheme.textSecondary)));
  }
}
