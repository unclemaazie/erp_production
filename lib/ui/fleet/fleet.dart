import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../models/vehicle.dart';
import 'vehicle_form.dart';
import 'trip_form.dart';

class Fleet extends ConsumerStatefulWidget {
  const Fleet({super.key});

  @override
  ConsumerState<Fleet> createState() => _FleetState();
}

class _FleetState extends ConsumerState<Fleet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tab = i),
          tabs: const [
            Tab(text: 'Vehicles'),
            Tab(text: 'Trips'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _VehiclesTab(onChanged: () => setState(() {})),
          const _TripsTab(),
          const _MaintenanceTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => VehicleFormDialog(onSaved: () => setState(() {})),
              ),
              child: const Icon(Icons.add),
            )
          : _tab == 1
              ? FloatingActionButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => TripFormDialog(onSaved: () => setState(() {})),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}

class _VehiclesTab extends StatelessWidget {
  final VoidCallback onChanged;
  const _VehiclesTab({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Vehicle>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No vehicles', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final v = list[i];
            Color statusColor = AppTheme.success;
            if (v.status == 'maintenance') statusColor = AppTheme.warning;
            if (v.status == 'retired') statusColor = AppTheme.danger;
            return ListTile(
              leading: const Icon(Icons.local_shipping, color: AppTheme.primary),
              title: Text('${v.make ?? ''} ${v.model ?? ''} (${v.registration})'),
              subtitle: Text('${v.year ?? ''} • ${v.status.toUpperCase()} • ${v.currentOdometer.toStringAsFixed(0)} km'),
              trailing: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Vehicle>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.query('vehicles', where: 'deleted_at IS NULL', orderBy: 'registration ASC');
    return rows.map(Vehicle.fromMap).toList();
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        if (list.isEmpty) return const Center(child: Text('No trips logged', style: TextStyle(color: AppTheme.textSecondary)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final t = list[i];
            return ListTile(
              leading: const Icon(Icons.route, color: AppTheme.accent),
              title: Text('${t.startLocation ?? 'Unknown'} → ${t.endLocation ?? 'Unknown'}'),
              subtitle: Text('${t.distance?.toStringAsFixed(1) ?? '?'} km • R ${t.fuelCost.toStringAsFixed(2)}'),
              trailing: Text(t.tripDate?.toIso8601String().split('T').first ?? ''),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _load() async {
    final db = await LocalDB.instance;
    final rows = await db.query('fleet_trips', orderBy: 'trip_date DESC');
    return rows.map((r) => r).toList();
  }
}

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Maintenance Schedule - Coming Soon', style: TextStyle(color: AppTheme.textSecondary)));
  }
}
