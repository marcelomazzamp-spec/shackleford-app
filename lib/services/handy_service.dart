import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart' as constants;
import '../models/models.dart';
import 'storage_service.dart';
import 'audio_service.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class HandyService {
  static IO.Socket? _socket;
  static ConnectionState _state = ConnectionState.disconnected;
  static Member? _currentMember;
  
  // Streams
  static final _stateController = StreamController<ConnectionState>.broadcast();
  static final _messageController = StreamController<HandyMessage>.broadcast();
  static final _alertController = StreamController<Map<String, dynamic>>.broadcast();
  static final _onlineController = StreamController<List<int>>.broadcast();
  
  static Stream<ConnectionState> get stateStream => _stateController.stream;
  static Stream<HandyMessage> get messageStream => _messageController.stream;
  static Stream<Map<String, dynamic>> get alertStream => _alertController.stream;
  static Stream<List<int>> get onlineStream => _onlineController.stream;
  
  static ConnectionState get state => _state;
  static bool get isConnected => _state == ConnectionState.connected;
  
  static List<int> _onlineMembers = [];
  static List<int> get onlineMembers => _onlineMembers;
  
  // ============ CONEXIÓN ============
  
  static Future<void> connect() async {
    if (_state == ConnectionState.connecting || _state == ConnectionState.connected) {
      return;
    }
    
    _setState(ConnectionState.connecting);
    
    final token = await StorageService.getToken();
    final memberId = await StorageService.getMemberId();
    
    if (token == null || memberId == null) {
      _setState(ConnectionState.error);
      return;
    }
    
    _socket = IO.io(
      constants.AppConfig.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(30000)
          .build(),
    );
    
    _socket!.onConnect((_) {
      print('[Handy] Conectado, autenticando...');
      _socket!.emit('auth', {
        'token': token,
        'memberId': memberId,
      });
    });
    
    _socket!.on('auth:success', (data) {
      print('[Handy] Autenticado correctamente');
      _currentMember = Member.fromJson(data['member']);
      _setState(ConnectionState.connected);
      AudioService.playClick();
    });
    
    _socket!.on('auth:error', (data) {
      print('[Handy] Error de autenticación: ${data['message']}');
      _setState(ConnectionState.error);
    });
    
    // Mensaje de audio entrante
    _socket!.on('handy:incoming', (data) async {
      print('[Handy] Audio entrante de ${data['from']}');
      await AudioService.playIncoming();
      
      final message = HandyMessage(
        id: 0,
        fromMemberId: data['from'],
        fromName: data['fromName'] ?? 'Desconocido',
        messageType: 'audio',
        durationSeconds: data['duration'],
        createdAt: DateTime.now(),
        audioData: data['audio'] != null ? List<int>.from(data['audio']) : null,
      );
      
      _messageController.add(message);
      
      // Reproducir automáticamente
      if (message.audioData != null) {
        await AudioService.playAudio(Uint8List.fromList(message.audioData!));
      }
    });
    
    // Alerta bip-bip entrante
    _socket!.on('handy:alert', (data) async {
      print('[Handy] Alerta de ${data['from']}');
      await AudioService.playAlert();
      _alertController.add(data);
    });
    
    // Miembro online
    _socket!.on('member:online', (data) {
      final memberId = data['memberId'];
      if (!_onlineMembers.contains(memberId)) {
        _onlineMembers.add(memberId);
        _onlineController.add(_onlineMembers);
      }
    });
    
    // Miembro offline
    _socket!.on('member:offline', (data) {
      final memberId = data['memberId'];
      _onlineMembers.remove(memberId);
      _onlineController.add(_onlineMembers);
    });
    
    // Pánico recibido (solo admins)
    _socket!.on('panic:alert', (data) async {
      print('[Handy] 🆘 PÁNICO de ${data['memberName']}');
      await AudioService.playPanicAlarm();
      _alertController.add({
        'type': 'panic',
        ...data,
      });
    });
    
    // Anomalía detectada (solo admins)
    _socket!.on('alert:anomaly', (data) async {
      print('[Handy] Anomalía detectada');
      await AudioService.playAlert();
      _alertController.add({
        'type': 'anomaly',
        ...data,
      });
    });
    
    _socket!.onDisconnect((_) {
      print('[Handy] Desconectado');
      _setState(ConnectionState.disconnected);
    });
    
    _socket!.onError((error) {
      print('[Handy] Error: $error');
      _setState(ConnectionState.error);
    });
    
    _socket!.connect();
  }
  
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setState(ConnectionState.disconnected);
    _onlineMembers = [];
  }
  
  // ============ ENVÍO ============
  
  /// Enviar audio a un miembro
  static Future<bool> sendToMember(int toMemberId, Uint8List audio, int duration) async {
    if (!isConnected) return false;
    
    await AudioService.playChirpEnd();
    
    _socket!.emit('handy:send', {
      'toMemberId': toMemberId,
      'audio': audio.toList(),
      'duration': duration,
    });
    
    return true;
  }
  
  /// Enviar audio a un grupo
  static Future<bool> sendToGroup(String groupId, Uint8List audio, int duration) async {
    if (!isConnected) return false;
    
    await AudioService.playChirpEnd();
    
    _socket!.emit('handy:sendGroup', {
      'groupId': groupId,
      'audio': audio.toList(),
      'duration': duration,
    });
    
    return true;
  }
  
  /// Enviar alerta bip-bip
  static Future<bool> sendAlert(int toMemberId) async {
    if (!isConnected) return false;
    
    _socket!.emit('handy:alert', {
      'toMemberId': toMemberId,
    });
    
    return true;
  }
  
  // ============ UBICACIÓN ============
  
  static void sendLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    int? battery,
    bool isMoving = false,
    double? speed,
  }) {
    if (!isConnected) return;
    
    _socket!.emit('location:update', {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'battery': battery,
      'isMoving': isMoving,
      'speed': speed,
    });
  }
  
  // ============ PÁNICO ============
  
  static void sendPanic({
    required double latitude,
    required double longitude,
    Uint8List? audio,
    List<Uint8List>? photos,
  }) {
    if (!isConnected) return;
    
    _socket!.emit('panic', {
      'latitude': latitude,
      'longitude': longitude,
      'audio': audio?.toList(),
      'photos': photos?.map((p) => p.toList()).toList(),
    });
  }
  
  // ============ HELPERS ============
  
  static void _setState(ConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }
  
  static bool isMemberOnline(int memberId) {
    return _onlineMembers.contains(memberId);
  }
  
  static Future<void> dispose() async {
    disconnect();
    await _stateController.close();
    await _messageController.close();
    await _alertController.close();
    await _onlineController.close();
  }
}
