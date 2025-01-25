import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/shared_prefs.dart';

class UserModulesProvider with ChangeNotifier {
  UserModules userModulesStatus = UserModules();
  List<String> _userModules = [];

  List<String> get userModules => _userModules;

  set userModules(List<String> value) {
    _userModules = value;
    userModulesStatus.setUserModules(value);
    notifyListeners();
  }
}
