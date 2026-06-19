import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'sync_engine.dart';

class RealtimeEngine {
  final SyncEngine _sync;
  RealtimeChannels? _channel;

  RealtimeEngine(this._sync);

  void start() {
    if (!SupabaseConfig.isConfigured) return;
    _channel = Supabase.instance.client
        .channel('erp_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'erp_events',
          callback: (payload) => _handle(payload),
        )
        .subscribe();
  }

  void _handle(PostgresChangePayload payload) {
    if (kDebugMode) print('Realtime event: \${payload.eventType} on \${payload.table}');
    _sync.syncAll();
  }

  void stop() {
    _channel?.unsubscribe();
  }
}
