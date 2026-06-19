import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import '../sync/sync_engine.dart';

const String syncTaskName = 'erp.background.sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) print('Background sync started: \$task');
    try {
      final engine = SyncEngine();
      await engine.syncAll();
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) print('Background sync failed: \$e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
  }
}
