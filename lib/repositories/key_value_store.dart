/// Local key/value storage abstraction.
///
/// This indirection lets repositories persist data now (via SharedPreferences)
/// while allowing a later move to secure storage for sensitive material without
/// touching callers. The protected-apps list is not secret (unlike a PIN), so
/// plain local storage is acceptable for it; sensitive values will use a secure
/// implementation of this same interface later.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  Future<List<String>> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// In-memory implementation for tests and previews.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> _data = {};

  @override
  Future<List<String>> getStringList(String key) async {
    final v = _data[key];
    return v is List<String> ? List<String>.from(v) : <String>[];
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _data[key] = List<String>.from(value);
  }

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

/// SharedPreferences-backed implementation for production (local device storage).
class SharedPreferencesKeyValueStore implements KeyValueStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<String>> getStringList(String key) async =>
      (await _prefs).getStringList(key) ?? <String>[];

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      (await _prefs).setStringList(key, value);

  @override
  Future<String?> getString(String key) async => (await _prefs).getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      (await _prefs).setString(key, value);
}
