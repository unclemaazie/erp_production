import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/customer.dart';

class Customers extends ConsumerStatefulWidget {
  const Customers({super.key});

  @override
  ConsumerState<Customers> createState() => _CustomersState();
}

class _CustomersState extends ConsumerState<Customers> {
  late Future<List<Customer>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Customer>> _load() async {
    final db = await LocalDB.instance;
    if (_query.isEmpty) {
      final rows = await db.query('customers', where: 'deleted_at IS NULL', orderBy: 'name ASC');
      return rows.map(Customer.fromMap).toList();
    }
    final rows = await db.query(
      'customers',
      where: 'deleted_at IS NULL AND (name LIKE ? OR email LIKE ? OR phone LIKE ?)',
      whereArgs: ['%$_query%', '%$_query%', '%$_query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/customers/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _query = v;
                _refresh();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No customers found', style: TextStyle(color: AppTheme.textSecondary)));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary)),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.email ?? c.phone ?? 'No contact info', style: const TextStyle(color: AppTheme.textSecondary)),
                      trailing: Text('R ${c.balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => context.push('/customers/${c.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
