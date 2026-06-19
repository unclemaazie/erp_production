import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';

class EmployeeFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const EmployeeFormDialog({super.key, required this.onSaved});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _empNumCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _hourlyCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  DateTime? _startDate;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    await db.insert('employees', {
      'id': const Uuid().v4(),
      'employee_number': _empNumCtrl.text.trim().isEmpty ? null : _empNumCtrl.text.trim(),
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'department': _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      'job_title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      'salary': double.tryParse(_salaryCtrl.text),
      'hourly_rate': double.tryParse(_hourlyCtrl.text),
      'start_date': _startDate?.toIso8601String(),
      'bank_details': _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
      'sync_status': 0,
    });
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Employee'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextField(controller: _empNumCtrl, decoration: const InputDecoration(labelText: 'Employee Number')),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
              TextField(controller: _salaryCtrl, decoration: const InputDecoration(labelText: 'Monthly Salary'), keyboardType: TextInputType.number),
              TextField(controller: _hourlyCtrl, decoration: const InputDecoration(labelText: 'Hourly Rate'), keyboardType: TextInputType.number),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_startDate?.toIso8601String().split('T').first ?? 'Not set'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _startDate = d);
                },
              ),
              TextField(controller: _bankCtrl, decoration: const InputDecoration(labelText: 'Bank Details'), maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
