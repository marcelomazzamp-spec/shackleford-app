import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/handy_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class AppProvider extends ChangeNotifier {
  // Estado
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Member? _currentMember;
  List<Member> _members = [];
  List<MemberLocation> _locations = [];
  List<AppEvent> _events = [];
  List<AppEvent> _unreadEvents = [];
  AppConfig? _config;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Member? get currentMember => _currentMember;
  List<Member> get members => _members;
  List<MemberLocation> get locations => _locations;
  List<AppEvent> get events => _events;
  List<AppEvent> get unreadEvents => _unreadEvents;
  int get unreadCount => _unreadEvents.length;
  AppConfig? get config => _config;
  bool get isAdmin => _currentMember?.isAdmin ?? false;
  
  // ============ INICIALIZACIÓN ============
  
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    await StorageService.init();
    await AudioService.init();
    
    _isLoggedIn = await StorageService.isLoggedIn();
    
    if (_isLoggedIn) {
      _currentMember = await StorageService.getMember();
      _config = StorageService.getConfig();
      
      // Conectar servicios
      await HandyService.connect();
      await LocationService.startTracking(
        interval: _config?.gpsInterval ?? 300,
      );
      
      // Cargar datos
      await refreshData();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // ============ AUTH ============
  
  Future<bool> login(String inviteCode) async {
    _isLoading = true;
    notifyListeners();
    
    // Obtener IMEI/ID del dispositivo
    final imei = DateTime.now().millisecondsSinceEpoch.toString();
    
    final result = await ApiService.register(inviteCode, imei);
    
    if (result != null && result['success'] == true) {
      final token = result['token'];
      final member = Member.fromJson(result['member']);
      
      await StorageService.saveAuth(token, member);
      
      _currentMember = member;
      _isLoggedIn = true;
      
      // Conectar servicios
      await HandyService.connect();
      await LocationService.startTracking();
      
      // Cargar datos
      await refreshData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<void> logout() async {
    HandyService.disconnect();
    LocationService.stopTracking();
    await StorageService.clearAuth();
    
    _isLoggedIn = false;
    _currentMember = null;
    _members = [];
    _locations = [];
    _events = [];
    _unreadEvents = [];
    
    notifyListeners();
  }
  
  // ============ DATOS ============
  
  Future<void> refreshData() async {
    await Future.wait([
      refreshMembers(),
      refreshLocations(),
      refreshEvents(),
      refreshConfig(),
    ]);
  }
  
  Future<void> refreshMembers() async {
    _members = await ApiService.getMembers();
    notifyListeners();
  }
  
  Future<void> refreshLocations() async {
    _locations = await ApiService.getLocations();
    notifyListeners();
  }
  
  Future<void> refreshEvents() async {
    _events = await ApiService.getEvents();
    _unreadEvents = await ApiService.getUnreadEvents();
    notifyListeners();
  }
  
  Future<void> refreshConfig() async {
    _config = await ApiService.getConfig();
    if (_config != null) {
      await StorageService.saveConfig(_config!);
      LocationService.updateInterval(_config!.gpsInterval);
    }
    notifyListeners();
  }
  
  Future<void> markEventRead(int eventId) async {
    await ApiService.markEventRead(eventId);
    _unreadEvents.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }
  
  // ============ HELPERS ============
  
  Member? getMember(int id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
  
  MemberLocation? getMemberLocation(int memberId) {
    try {
      return _locations.firstWhere((l) => l.memberId == memberId);
    } catch (e) {
      return null;
    }
  }
  
  List<Member> get otherMembers {
    return _members.where((m) => m.id != _currentMember?.id).toList();
  }
  
  List<Member> get children {
    return _members.where((m) => m.isChild).toList();
  }
  
  List<Member> get admins {
    return _members.where((m) => m.isAdmin).toList();
  }
}
