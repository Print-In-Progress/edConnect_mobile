import 'package:flutter/material.dart';
import 'package:edconnect_mobile/models/shared_prefs.dart';

class ThemeProvider with ChangeNotifier {
  ThemePreference themePreference = ThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    themePreference.setDarkTheme(value);
    notifyListeners();
  }
}

class ColorANDLogoProvider with ChangeNotifier {
  CurrentColorScheme colors = CurrentColorScheme();
  String _primaryColor = '0xFF192B4C';
  String _secondaryColor = '0xFF01629C';
  String _logoLink = '';
  String _customerName = '';

  String get primaryColor => _primaryColor;
  String get secondaryColor => _secondaryColor;
  String get logoLink => _logoLink;
  String get customerName => _customerName;

  void setPrimaryColor(String value) {
    _primaryColor = value;
    colors.setPrimaryColor(value);
    notifyListeners();
  }

  void setSecondaryColor(String value) {
    _secondaryColor = value;
    colors.setSecondaryColor(value);
    notifyListeners();
  }

  void setLogoLink(String value) {
    _logoLink = value;
    colors.setLogoLink(value);
    notifyListeners();
  }

  void setCustomerName(String value) {
    _customerName = value;
    colors.setCustomerName(value);
    notifyListeners();
  }

  set customerName(String value) {
    _customerName = value;
    colors.setCustomerName(value);
    notifyListeners();
  }
}
