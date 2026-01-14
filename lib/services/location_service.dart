import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'handy_service.dart';
import 'storage_service.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _lastPosition;
  static final Battery _battery = Battery();
  static Timer? _reportTimer;
  
  static int _currentInterval = 300; // 5 minutos default
  static bool _isTracking = false;
  
  static Position? get lastPosition => _lastPosition;
  static bool get isTracking => _isTracking;
  
  // ============ PERMISOS ============
  
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
  
  // ============ TRACKING ============
  
  static Future<void> startTracking({int? interval}) async {
    if (_isTracking) return;
    
    final hasPermission = await checkPermission();
    if (!hasPermission) return;
    
    _currentInterval = interval ?? _currentInterval;
    _isTracking = true;
    
    // Obtener posición inicial
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _reportPosition(_lastPosition!);
    } catch (e) {
      print('[Location] Error obteniendo posición inicial: $e');
    }
    
    // Configurar stream de posición
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // metros mínimos para update
      ),
    ).listen((Position position) {
      _lastPosition = position;
    });
    
    // Timer para reportar al servidor
    _startReportTimer();
  }
  
  static void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _positionStream = null;
    _reportTimer?.cancel();
    _reportTimer = null;
  }
  
  static void updateInterval(int seconds) {
    _currentInterval = seconds;
    if (_isTracking) {
      _reportTimer?.cancel();
      _startReportTimer();
    }
  }
  
  // ============ REPORTES ============
  
  static void _startReportTimer() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      Duration(seconds: _currentInterval),
      (_) async {
        if (_lastPosition != null) {
          await _reportPosition(_lastPosition!);
        }
      },
    );
  }
  
  static Future<void> _reportPosition(Position position) async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final isMoving = position.speed > 1.0; // m/s
      
      HandyService.sendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        battery: batteryLevel,
        isMoving: isMoving,
        speed: position.speed * 3.6, // m/s a km/h
      );
      
      print('[Location] Reportado: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('[Location] Error reportando: $e');
    }
  }
  
  // ============ UTILIDADES ============
  
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('[Location] Error: $e');
      return null;
    }
  }
  
  static double calculateDistance(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  static Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }
  
  static Future<void> dispose() async {
    stopTracking();
  }
}
