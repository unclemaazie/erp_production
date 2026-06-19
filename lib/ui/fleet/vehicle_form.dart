import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';

class VehicleFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const VehicleFormDialog({super.key, required this.onSaved});

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _regCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _vinCtrl = TextEditingController();
  final _odoCtrl = TextEditingController();
  String _fuel = 'diesel';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    await db.insert('vehicles', {
      'id': const Uuid().v4(),
      'registration': _regCtrl.text.trim().toUpperCase(),
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'year': int.tryParse(_yearCtrl.text),
      'vin': _vinCtrl.text.trim().isEmpty ? null : _vinCtrl.text.trim(),
      'status': 'active',
      'current_odometer': double.tryParse(_odoCtrl.text) ?? 0,
      'fuel_type': _fuel,
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
      title: const Text('New Vehicle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _regCtrl,
                decoration: const InputDecoration(labelText: 'Registration *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              TextField(controller: _makeCtrl, decoration: const InputDecoration(labelText: 'Make')),
              TextField(controller: _modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
              TextField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
              TextField(controller: _vinCtrl, decoration: const InputDecoration(labelText: 'VIN')),
              TextField(controller: _odoCtrl, decoration: const InputDecoration(labelText: 'Current Odometer'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: _fuel,
                decoration: const InputDecoration(labelText: 'Fuel Type'),
                items: const [
                  DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                  DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                  DropdownMenuItem(value: 'electric', child: Text('Electric')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                ],
                onChanged: (v) => setState(() => _fuel = v!),
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
