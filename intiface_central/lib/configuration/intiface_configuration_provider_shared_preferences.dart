import 'package:intiface_central/configuration/intiface_configuration_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntifaceConfigurationProviderSharedPreferences extends IntifaceConfigurationProvider {
  final SharedPreferences _prefs;

  IntifaceConfigurationProviderSharedPreferences._create(this._prefs);

  static Future<IntifaceConfigurationProviderSharedPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return IntifaceConfigurationProviderSharedPreferences._create(prefs);
  }

  bool? getBool(String name) {
    return _prefs.getBool(name);
  }

  String? getString(String name) {
    return _prefs.getString(name);
  }

  int? getInt(String name) {
    return _prefs.getInt(name);
  }

  void setBool(String key, bool value) {
    _prefs.setBool(key, value);
  }

  void setString(String key, String value) {
    _prefs.setString(key, value);
  }

  void setInt(String key, int value) {
    _prefs.setInt(key, value);
  }
}
