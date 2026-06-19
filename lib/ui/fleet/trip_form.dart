import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/vehicle.dart';

class TripFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const TripFormDialog({super.key, required this.onSaved});

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleId;
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _startOdoCtrl = TextEditingController();
  final _endOdoCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final db = await LocalDB.instance;
    final rows = await db.query('vehicles', where: "deleted_at IS NULL AND status = 'active'", orderBy: 'registration ASC');
    setState(() => _vehicles = rows.map(Vehicle.fromMap).toList());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _vehicleId == null) return;
    final db = await LocalDB.instance;
    final now = DateTime.now().toIso8601String();
    final startOdo = double.tryParse(_startOdoCtrl.text) ?? 0;
    final endOdo = double.tryParse(_endOdoCtrl.text) ?? 0;
    await db.insert('fleet_trips', {
      'id': const Uuid().v4(),
      'vehicle_id': _vehicleId,
      'start_location': _startCtrl.text.trim(),
      'end_location': _endCtrl.text.trim(),
      'start_odometer': startOdo,
      'end_odometer': endOdo,
      'distance': endOdo - startOdo,
      'purpose': _purposeCtrl.text.trim(),
      'fuel_cost': double.tryParse(_fuelCtrl.text) ?? 0,
      'trip_date': _date.toIso8601String(),
      'created_at': now,
      'sync_status': 0,
    });
    // Update vehicle odometer
    await db.update('vehicles', {
      'current_odometer': endOdo,
      'updated_at': now,
      'sync_status': 0,
    }, where: 'id = ?', whereArgs: [_vehicleId]);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Trip'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _vehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle *'),
                items: _vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.registration))).toList(),
                onChanged: (v) => setState(() => _vehicleId = v),
                validator: (v) => v == null ? 'Select vehicle' : null,
              ),
              TextField(controller: _startCtrl, decoration: const InputDecoration(labelText: 'Start Location')),
              TextField(controller: _endCtrl, decoration: const InputDecoration(labelText: 'End Location')),
              TextField(controller: _startOdoCtrl, decoration: const InputDecoration(labelText: 'Start Odometer'), keyboardType: TextInputType.number),
              TextField(controller: _endOdoCtrl, decoration: const InputDecoration(labelText: 'End Odometer'), keyboardType: TextInputType.number),
              TextField(controller: _purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
              TextField(controller: _fuelCtrl, decoration: const InputDecoration(labelText: 'Fuel Cost'), keyboardType: TextInputType.number),
              ListTile(
                title: const Text('Trip Date'),
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
