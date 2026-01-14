/// SHACKLEFORD - Modelos de datos

class Member {
  final int id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? deviceToken;
  final bool isActive;
  
  Member({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.deviceToken,
    this.isActive = true,
  });
  
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      deviceToken: json['device_token'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
  
  bool get isAdmin => role == 'admin';
  bool get isChild => role == 'child';
  
  String get avatar {
    if (isAdmin) return '👨';
    return '👦';
  }
}

class MemberLocation {
  final int memberId;
  final String memberName;
  final double latitude;
  final double longitude;
  final int? batteryLevel;
  final String? connectionType;
  final DateTime recordedAt;
  
  MemberLocation({
    required this.memberId,
    required this.memberName,
    required this.latitude,
    required this.longitude,
    this.batteryLevel,
    this.connectionType,
    required this.recordedAt,
  });
  
  factory MemberLocation.fromJson(Map<String, dynamic> json) {
    return MemberLocation(
      memberId: json['member_id'],
      memberName: json['member_name'] ?? 'Desconocido',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      batteryLevel: json['battery_level'],
      connectionType: json['connection_type'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
  
  bool get isRecent {
    return DateTime.now().difference(recordedAt).inMinutes < 10;
  }
}

class HandyMessage {
  final int id;
  final int fromMemberId;
  final String fromName;
  final int? toMemberId;
  final String? toName;
  final String? groupId;
  final String messageType;
  final int? durationSeconds;
  final DateTime createdAt;
  final List<int>? audioData;
  
  HandyMessage({
    required this.id,
    required this.fromMemberId,
    required this.fromName,
    this.toMemberId,
    this.toName,
    this.groupId,
    required this.messageType,
    this.durationSeconds,
    required this.createdAt,
    this.audioData,
  });
  
  factory HandyMessage.fromJson(Map<String, dynamic> json) {
    return HandyMessage(
      id: json['id'] ?? 0,
      fromMemberId: json['from_member_id'] ?? json['from'],
      fromName: json['from_name'] ?? 'Desconocido',
      toMemberId: json['to_member_id'],
      toName: json['to_name'],
      groupId: json['group_id'],
      messageType: json['message_type'] ?? 'audio',
      durationSeconds: json['duration_seconds'] ?? json['duration'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      audioData: json['audio'] != null ? List<int>.from(json['audio']) : null,
    );
  }
  
  bool get isAudio => messageType == 'audio';
  bool get isAlert => messageType == 'alert';
  bool get isGroup => groupId != null;
  
  String get durationFormatted {
    if (durationSeconds == null) return '0:00';
    final mins = durationSeconds! ~/ 60;
    final secs = durationSeconds! % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

class AppEvent {
  final int id;
  final int? memberId;
  final String? memberName;
  final String eventType;
  final int alertLevel;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  
  AppEvent({
    required this.id,
    this.memberId,
    this.memberName,
    required this.eventType,
    required this.alertLevel,
    this.latitude,
    this.longitude,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });
  
  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      id: json['id'],
      memberId: json['member_id'],
      memberName: json['member_name'],
      eventType: json['event_type'],
      alertLevel: json['alert_level'] ?? 1,
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      data: json['data'] != null ? (json['data'] is String ? {} : json['data']) : null,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  String get icon {
    switch (eventType) {
      case 'panic': return '🆘';
      case 'voice_alert': return '🔊';
      case 'geofence_enter': return '📍';
      case 'geofence_exit': return '📍';
      case 'wifi_blocked': return '📶';
      case 'device_new': return '📱';
      case 'power_outage': return '⚡';
      case 'low_battery': return '🔋';
      default: return '📌';
    }
  }
  
  String get title {
    switch (eventType) {
      case 'panic': return 'EMERGENCIA';
      case 'voice_alert': return 'Alerta de voz';
      case 'geofence_enter': return 'Entrada a zona';
      case 'geofence_exit': return 'Salida de zona';
      case 'wifi_blocked': return 'WiFi bloqueado';
      case 'device_new': return 'Nuevo dispositivo';
      case 'power_outage': return 'Corte de luz';
      case 'low_battery': return 'Batería baja';
      default: return eventType;
    }
  }
  
  bool get isCritical => alertLevel >= 3;
}

class AppConfig {
  final String mode;
  final int gpsInterval;
  final String handyMode;
  final bool syncEnabled;
  final bool voiceMonitorActive;
  final int voiceThresholdDb;
  
  AppConfig({
    required this.mode,
    required this.gpsInterval,
    required this.handyMode,
    required this.syncEnabled,
    required this.voiceMonitorActive,
    required this.voiceThresholdDb,
  });
  
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      mode: json['mode'] ?? 'normal',
      gpsInterval: json['gps_interval'] ?? 300,
      handyMode: json['handy_mode'] ?? 'full',
      syncEnabled: json['sync_enabled'] ?? true,
      voiceMonitorActive: json['voice_monitor_active'] ?? false,
      voiceThresholdDb: json['voice_threshold_db'] ?? 75,
    );
  }
}
