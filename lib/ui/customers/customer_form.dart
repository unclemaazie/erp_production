import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/customer.dart';

class CustomerForm extends ConsumerStatefulWidget {
  final String? customerId;
  const CustomerForm({super.key, this.customerId});

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();
  final _billingCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();
  bool _isEdit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _isEdit = true;
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    final db = await LocalDB.instance;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [widget.customerId]);
    if (rows.isNotEmpty) {
      final c = Customer.fromMap(rows.first);
      _nameCtrl.text = c.name;
      _emailCtrl.text = c.email ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _vatCtrl.text = c.vatNumber ?? '';
      _billingCtrl.text = c.billingAddress ?? '';
      _shippingCtrl.text = c.shippingAddress ?? '';
      _creditCtrl.text = c.creditLimit.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = await LocalDB.instance;
    final id = widget.customerId ?? const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final map = {
      'id': id,
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'vat_number': _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim(),
      'billing_address': _billingCtrl.text.trim().isEmpty ? null : _billingCtrl.text.trim(),
      'shipping_address': _shippingCtrl.text.trim().isEmpty ? null : _shippingCtrl.text.trim(),
      'credit_limit': double.tryParse(_creditCtrl.text) ?? 0,
      'payment_terms': 30,
      'is_active': 1,
      'balance_due': 0,
      'updated_at': now,
      'sync_status': 0,
    };

    if (!_isEdit) {
      map['created_at'] = now;
      await db.insert('customers', map);
    } else {
      await db.update('customers', map, where: 'id = ?', whereArgs: [id]);
    }

    // Queue sync
    await db.insert('outbox', {
      'table_name': 'customers',
      'operation': _isEdit ? 'UPDATE' : 'INSERT',
      'payload': map.toString(),
      'record_id': id,
      'synced': 0,
      'created_at': now,
    });

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Customer' : 'New Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vatCtrl,
                decoration: const InputDecoration(labelText: 'VAT Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _billingCtrl,
                decoration: const InputDecoration(labelText: 'Billing Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shippingCtrl,
                decoration: const InputDecoration(labelText: 'Shipping Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditCtrl,
                decoration: const InputDecoration(labelText: 'Credit Limit'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
