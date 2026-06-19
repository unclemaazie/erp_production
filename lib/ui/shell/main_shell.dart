import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  final _destinations = const [
    _NavItem('/dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem('/customers', Icons.people_outline, Icons.people, 'Customers'),
    _NavItem('/invoices', Icons.receipt_outlined, Icons.receipt, 'Invoices'),
    _NavItem('/payments', Icons.payments_outlined, Icons.payments, 'Payments'),
    _NavItem('/accounting', Icons.bar_chart_outlined, Icons.bar_chart, 'Accounting'),
    _NavItem('/fleet', Icons.local_shipping_outlined, Icons.local_shipping, 'Fleet'),
    _NavItem('/warehouse', Icons.warehouse_outlined, Icons.warehouse, 'Warehouse'),
    _NavItem('/payroll', Icons.work_outline, Icons.work, 'Payroll'),
    _NavItem('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncStateProvider);
    final auth = ref.watch(authProvider);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 700;

    void onNav(int i) {
      setState(() => _index = i);
      context.go(_destinations[i].path);
    }

    final navRail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: onNav,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.business, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            if (sync.pendingCount > 0)
              Badge(
                label: Text('${sync.pendingCount}'),
                child: IconButton(
                  icon: Icon(
                    sync.isSyncing ? Icons.sync : Icons.cloud_off,
                    color: sync.isSyncing ? AppTheme.accent : AppTheme.warning,
                  ),
                  onPressed: sync.isSyncing ? null : () => sync.syncAll(),
                  tooltip: sync.lastError ?? 'Sync now',
                ),
              )
            else
              IconButton(
                icon: Icon(
                  sync.isSyncing ? Icons.sync : Icons.cloud_done,
                  color: sync.isSyncing ? AppTheme.accent : AppTheme.success,
                ),
                onPressed: sync.isSyncing ? null : () => sync.syncAll(),
                tooltip: sync.lastError ?? 'Sync now',
              ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.logout, color: AppTheme.danger),
        onPressed: () => ref.read(authProvider.notifier).signOut(),
        tooltip: 'Logout',
      ),
      destinations: _destinations.map((d) => NavigationRailDestination(
        icon: Icon(d.icon),
        selectedIcon: Icon(d.selectedIcon),
        label: Text(d.label),
      )).toList(),
    );

    final bottomNav = BottomNavigationBar(
      currentIndex: _index,
      onTap: onNav,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardBg,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      items: _destinations.map((d) => BottomNavigationBarItem(
        icon: Icon(d.icon),
        activeIcon: Icon(d.selectedIcon),
        label: d.label,
      )).toList(),
    );

    return Scaffold(
      body: isCompact
          ? Column(
              children: [
                if (sync.isSyncing)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(child: widget.child),
              ],
            )
          : Row(
              children: [
                navRail,
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      if (sync.isSyncing)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isCompact ? bottomNav : null,
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);
}
