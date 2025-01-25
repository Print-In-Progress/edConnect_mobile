import 'package:shared_preferences/shared_preferences.dart';

class ThemePreference {
  static const themeStatus = "THEMESTATUS";

  setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(themeStatus, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeStatus) ?? false;
  }
}

class CurrentOrg {
  static const currentOrg = "ORG";

  setOrg(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(currentOrg, value);
  }

  Future<String> getOrg() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentOrg) ?? '';
  }
}

class UserModules {
  static const userModulesSharedPrefs = "USERMODULES";

  setUserModules(List<String> value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(userModulesSharedPrefs, value);
  }

  Future<List<String>> getUserModules() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(userModulesSharedPrefs) ?? [];
  }
}

class CurrentColorScheme {
  static const primaryColor = "PRIMARYCOLOR";
  static const secondaryColor = "SECONDARYCOLOR";
  static const logoLink = 'LOGOLINK';
  static const customerName = 'CUSTOMERNAME';

  setPrimaryColor(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(primaryColor, value);
  }

  setSecondaryColor(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(secondaryColor, value);
  }

  setLogoLink(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(logoLink, value);
  }

  setCustomerName(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(customerName, value);
  }

  Future<String> getPrimaryColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(primaryColor) ?? '';
  }

  Future<String> getSecondaryColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(secondaryColor) ?? '';
  }

  Future<String> getLogoLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(logoLink) ?? '';
  }

  Future<String> getCustomerName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(customerName) ?? '';
  }
}
