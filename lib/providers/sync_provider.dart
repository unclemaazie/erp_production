import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine();
  ref.onDispose(() {});
  return engine;
});

final syncStateProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  return ref.watch(syncEngineProvider);
});
