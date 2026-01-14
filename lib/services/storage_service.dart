import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static SharedPreferences? _prefs;
  
  // Keys
  static const String _keyToken = 'auth_token';
  static const String _keyMemberId = 'member_id';
  static const String _keyMember = 'member_data';
  static const String _keyConfig = 'app_config';
  static const String _keyFirstLaunch = 'first_launch';
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ============ AUTH ============
  
  static Future<void> saveAuth(String token, Member member) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyMemberId, value: member.id.toString());
    await _prefs?.setString(_keyMember, jsonEncode({
      'id': member.id,
      'name': member.name,
      'role': member.role,
      'email': member.email,
    }));
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }
  
  static Future<int?> getMemberId() async {
    final id = await _storage.read(key: _keyMemberId);
    return id != null ? int.parse(id) : null;
  }
  
  static Future<Member?> getMember() async {
    final data = _prefs?.getString(_keyMember);
    if (data == null) return null;
    return Member.fromJson(jsonDecode(data));
  }
  
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  static Future<void> clearAuth() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyMemberId);
    await _prefs?.remove(_keyMember);
  }
  
  // ============ CONFIG ============
  
  static Future<void> saveConfig(AppConfig config) async {
    await _prefs?.setString(_keyConfig, jsonEncode({
      'mode': config.mode,
      'gps_interval': config.gpsInterval,
      'handy_mode': config.handyMode,
      'sync_enabled': config.syncEnabled,
      'voice_monitor_active': config.voiceMonitorActive,
      'voice_threshold_db': config.voiceThresholdDb,
    }));
  }
  
  static AppConfig? getConfig() {
    final data = _prefs?.getString(_keyConfig);
    if (data == null) return null;
    return AppConfig.fromJson(jsonDecode(data));
  }
  
  // ============ FIRST LAUNCH ============
  
  static bool isFirstLaunch() {
    return _prefs?.getBool(_keyFirstLaunch) ?? true;
  }
  
  static Future<void> setFirstLaunchDone() async {
    await _prefs?.setBool(_keyFirstLaunch, false);
  }
  
  // ============ GENERAL ============
  
  static Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  static String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
}
