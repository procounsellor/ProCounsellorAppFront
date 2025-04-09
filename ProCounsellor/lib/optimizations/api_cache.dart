import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiCache {
  static final Map<String, dynamic> _cache = {}; // In-memory cache

  /// Store API response in cache (Optionally persist to SharedPreferences)
  static Future<void> set(String key, dynamic value,
      {bool persist = false}) async {
    _cache[key] = value;

    if (persist) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(key, json.encode(value));
    }
  }

  /// Retrieve cached response (returns null if not found)
  static dynamic get(String key) {
    return _cache[key];
  }

  /// Retrieve persisted data from SharedPreferences
  static Future<dynamic> getPersisted(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(key);
    return data != null ? json.decode(data) : null;
  }

  /// Clear cache (Optionally clear SharedPreferences as well)
  static Future<void> clear({bool clearPersistent = false}) async {
    _cache.clear();
    if (clearPersistent) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}
