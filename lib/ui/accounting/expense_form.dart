import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';

class ExpenseFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const ExpenseFormDialog({super.key, required this.onSaved});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'travel';
  DateTime _date = DateTime.now();
  String? _receiptPath;

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
    if (file != null) {
      setState(() => _receiptPath = file.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    await db.insert('expenses', {
      'id': const Uuid().v4(),
      'category': _category,
      'amount': double.parse(_amountCtrl.text),
      'expense_date': _date.toIso8601String(),
      'description': _descCtrl.text,
      'receipt_url': _receiptPath,
      'status': 'pending',
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
      title: const Text('New Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'travel', child: Text('Travel')),
                  DropdownMenuItem(value: 'meals', child: Text('Meals')),
                  DropdownMenuItem(value: 'office', child: Text('Office Supplies')),
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount *'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
              ),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_date.toIso8601String().split('T').first),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_receiptPath == null ? 'Attach Receipt' : 'Receipt attached'),
                onTap: _pickReceipt,
              ),
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
