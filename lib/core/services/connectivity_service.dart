import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty && results.first != ConnectivityResult.none;
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  Future<bool> checkNow() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }

  void dispose() => _controller.close();
}
