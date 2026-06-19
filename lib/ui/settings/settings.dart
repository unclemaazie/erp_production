import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/db/local_db.dart';
import '../../core/sync/sync_engine.dart';
import '../../providers/auth_provider.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncStateProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person, color: AppTheme.primary),
            title: Text(auth.profile?.fullName ?? auth.user?.email ?? 'Unknown'),
            subtitle: Text(auth.profile?.role ?? 'User'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
          const Divider(),
          _SectionHeader('Sync & Data'),
          ListTile(
            leading: Icon(
              sync.isSyncing ? Icons.sync : Icons.cloud_done,
              color: sync.isSyncing ? AppTheme.accent : AppTheme.success,
            ),
            title: Text(sync.isSyncing ? 'Syncing...' : 'Last sync: ${sync.lastSync?.toString().split('.').first ?? 'Never'}'),
            subtitle: sync.lastError != null ? Text(sync.lastError!, style: const TextStyle(color: AppTheme.danger)) : Text('${sync.pendingCount} pending changes'),
            trailing: TextButton(
              onPressed: sync.isSyncing ? null : () => sync.syncAll(),
              child: const Text('SYNC NOW'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.danger),
            title: const Text('Clear Local Data'),
            subtitle: const Text('Delete all local records. Use with caution.', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () => _confirmClearData(),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: AppTheme.primary),
            title: const Text('Export Data'),
            subtitle: const Text('Backup local database to file', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () => _exportData(),
          ),
          const Divider(),
          _SectionHeader('App'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            onTap: () {
              // TODO: open email or in-app report
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Local Data?'),
        content: const Text('This will delete all customers, invoices, and records stored on this device. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await LocalDB.reset();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local data cleared')),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    // TODO: implement DB export to JSON/SQL file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1),
      ),
    );
  }
}
