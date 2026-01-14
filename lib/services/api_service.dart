import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/models.dart';
import 'storage_service.dart';

class ApiService {
  static String get _baseUrl => AppConfig.apiUrl;
  static String get _rtUrl => AppConfig.rtUrl;
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // ============ AUTH ============
  
  static Future<Map<String, dynamic>?> register(String inviteCode, String imei) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': inviteCode,
          'imei': imei,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('[API] Error registro: $e');
      return null;
    }
  }
  
  // ============ MIEMBROS ============
  
  static Future<List<Member>> getMembers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/members'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['members'] as List)
            .map((m) => Member.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      print('[API] Error obteniendo miembros: $e');
      return [];
    }
  }
  
  // ============ UBICACIONES ============
  
  static Future<List<MemberLocation>> getLocations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/location'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['locations'] as List)
            .map((l) => MemberLocation.fromJson(l))
            .toList();
      }
      return [];
    } catch (e) {
      print('[API] Error obteniendo ubicaciones: $e');
      return [];
    }
  }
  
  // ============ EVENTOS ============
  
  static Future<List<AppEvent>> getEvents({int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/events'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['events'] as List)
            .map((e) => AppEvent.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[API] Error obteniendo eventos: $e');
      return [];
    }
  }
  
  static Future<List<AppEvent>> getUnreadEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/events/unread'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['events'] as List)
            .map((e) => AppEvent.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[API] Error: $e');
      return [];
    }
  }
  
  static Future<bool> markEventRead(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/events/read'),
        headers: headers,
        body: jsonEncode({'event_id': eventId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // ============ HANDY ============
  
  static Future<List<HandyMessage>> getHandyHistory({int limit = 50}) async {
    try {
      final memberId = await StorageService.getMemberId();
      final response = await http.get(
        Uri.parse('$_rtUrl/handy/history/$memberId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['messages'] as List)
            .map((m) => HandyMessage.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      print('[API] Error obteniendo historial handy: $e');
      return [];
    }
  }
  
  static Future<List<int>> getOnlineMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$_rtUrl/handy/online'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<int>.from(data['online']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // ============ CONFIG ============
  
  static Future<AppConfig?> getConfig() async {
    try {
      final memberId = await StorageService.getMemberId();
      final battery = await StorageService.getString('last_battery') ?? '100';
      
      final response = await http.get(
        Uri.parse('$_rtUrl/config/$memberId?battery=$battery'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppConfig.fromJson(data['config']);
      }
      return null;
    } catch (e) {
      print('[API] Error obteniendo config: $e');
      return null;
    }
  }
  
  // ============ RUTINAS ============
  
  static Future<Map<String, dynamic>?> getRoutines() async {
    try {
      final memberId = await StorageService.getMemberId();
      final response = await http.get(
        Uri.parse('$_rtUrl/routines/$memberId'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // ============ HEALTH CHECK ============
  
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_rtUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
