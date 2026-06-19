import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/employee.dart';
import 'employee_form.dart';

class Payroll extends ConsumerStatefulWidget {
  const Payroll({super.key});

  @override
  ConsumerState<Payroll> createState() => _PayrollState();
}

class _PayrollState extends ConsumerState<Payroll> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tab = i),
          tabs: const [
            Tab(text: 'Employees'),
            Tab(text: 'Payroll Runs'),
            Tab(text: 'Payslips'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _EmployeesTab(onChanged: () => setState(() {})),
          const _PayrollRunsTab(),
          const _PayslipsTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => EmployeeFormDialog(onSaved: () => setState(() {})),
              ),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

class _EmployeesTab extends StatelessWidget {
  final VoidCallback onChanged;
  const _EmployeesTab({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No employees', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i] as Employee;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(e.fullName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary)),
              ),
              title: Text(e.fullName),
              subtitle: Text('${e.department ?? 'No dept'} • ${e.jobTitle ?? 'No title'}'),
              trailing: Text(
                e.salary != null ? 'R ${e.salary!.toStringAsFixed(2)}' : 'R ${e.hourlyRate?.toStringAsFixed(2) ?? '0'}/hr',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Employee>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.query('employees', where: 'deleted_at IS NULL', orderBy: 'full_name ASC');
    return rows.map(Employee.fromMap).toList();
  }
}

class _PayrollRunsTab extends StatelessWidget {
  const _PayrollRunsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Payroll Runs - Coming Soon', style: TextStyle(color: AppTheme.textSecondary)));
  }
}

class _PayslipsTab extends StatelessWidget {
  const _PayslipsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Payslips - Coming Soon', style: TextStyle(color: AppTheme.textSecondary)));
  }
}
