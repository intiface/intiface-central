abstract class IntifaceConfigurationProvider {
  bool? getBool(String name);
  String? getString(String name);
  int? getInt(String name);
  void setBool(String key, bool value);
  void setString(String key, String value);
  void setInt(String key, int value);
}
