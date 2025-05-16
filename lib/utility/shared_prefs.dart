import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _sharedPreferences;

  static setString({required String key, required String value}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return await _sharedPreferences?.setString(key, value);
  }

  static Future<String?> getString({required String key}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences?.getString(key);
  }

  static setInt({required String key, required int value}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return await _sharedPreferences?.setInt(key, value);
  }

  static Future<int?> getInt({required String key}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences?.getInt(key);
  }

  static setBool({required String key, required bool value}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return await _sharedPreferences?.setBool(key, value);
  }

  static Future<bool?> getBool({required String key}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences?.getBool(key);
  }

  static setDouble({required String key, required double value}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return await _sharedPreferences?.setDouble(key, value);
  }

  static Future<double?> getDouble({required String key}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences?.getDouble(key);
  }

  static setStringList(
      {required String key, required List<String> list}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return await _sharedPreferences?.setStringList(key, list);
  }

  static Future<List<String>?> getStringList({required String key}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences?.getStringList(key);
  }
}
