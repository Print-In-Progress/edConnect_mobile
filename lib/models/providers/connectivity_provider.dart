import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  List<ConnectivityResult> _connectivityResults = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectivity(result);
    });
  }

  List<ConnectivityResult> get connectivityResults => _connectivityResults;

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    if (_connectivityResults != results) {
      _connectivityResults = results;
      notifyListeners();
    }
  }
}
