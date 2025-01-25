import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/shared_prefs.dart';

class OrgProvider with ChangeNotifier {
  CurrentOrg currentOrg = CurrentOrg();
  String _org = '';
  Function? fetchUserModules;

  OrgProvider({this.fetchUserModules});

  String get org => _org;
  set org(String value) {
    _org = value;
    currentOrg.setOrg(value);
    notifyListeners();
    fetchUserModules?.call();
  }
}
