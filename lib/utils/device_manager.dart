import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceManager {
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> getUniqueDeviceId() async {
    String? deviceId = await _secureStorage.read(key: 'device_id');

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await _secureStorage.write(key: 'device_id', value: deviceId);
    }

    return deviceId;
  }

  Future<String> _generateDeviceId() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return '${webInfo.browserName}-${webInfo.platform}-${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else {
      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return {
        'deviceType': 'Web',
        'browserName': webInfo.browserName,
        'platform': webInfo.platform,
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'deviceType': 'Android',
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'version': androidInfo.version.release,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'deviceType': 'iOS',
        'model': iosInfo.model,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
      };
    } else {
      return {
        'deviceType': 'Unknown',
      };
    }
  }
}
