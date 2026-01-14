/// SHACKLEFORD SECURITY
/// Configuración y constantes

class AppConfig {
  // Servidor
  static const String baseUrl = 'https://shak.marcelomazzabureauinmobilario.com';
  static const String wsUrl = 'wss://shak.marcelomazzabureauinmobilario.com/ws';
  static const String apiUrl = '$baseUrl/api';
  static const String rtUrl = '$baseUrl/rt';
  
  // App
  static const String appName = 'SHACKLEFORD';
  static const String appTagline = 'Protección sin exposición';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const int connectionTimeout = 30;
  static const int pttMaxDuration = 60; // segundos máximo de grabación
  
  // GPS
  static const int gpsIntervalIdle = 300; // 5 min
  static const int gpsIntervalMoving = 30; // 30 seg
  static const int gpsIntervalEmergency = 10; // 10 seg
}

class AppColors {
  // Colores principales
  static const int primaryBlack = 0xFF0A0A0A;
  static const int secondaryBlack = 0xFF1A1A1A;
  static const int cardBlack = 0xFF252525;
  static const int borderGray = 0xFF2A2A2A;
  
  // Acentos
  static const int accentRed = 0xFFDC2626;
  static const int accentRedDark = 0xFFB91C1C;
  static const int accentSilver = 0xFFC0C0C0;
  
  // Estados
  static const int success = 0xFF22C55E;
  static const int warning = 0xFFF59E0B;
  static const int danger = 0xFFEF4444;
  static const int info = 0xFF3B82F6;
  
  // Texto
  static const int textPrimary = 0xFFFFFFFF;
  static const int textSecondary = 0xFF888888;
  static const int textMuted = 0xFF555555;
}

class AppSounds {
  static const String chirpConnect = 'assets/sounds/nextel_chirp.mp3';
  static const String chirpDisconnect = 'assets/sounds/nextel_end.mp3';
  static const String beepIncoming = 'assets/sounds/nextel_incoming.mp3';
  static const String alertUrgent = 'assets/sounds/alert_urgent.mp3';
  static const String panicAlarm = 'assets/sounds/panic_alarm.mp3';
  static const String clickSoft = 'assets/sounds/click.mp3';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String handy = '/handy';
  static const String map = '/map';
  static const String events = '/events';
  static const String settings = '/settings';
  static const String panic = '/panic';
}

class HandyGroups {
  static const String familia = 'familia';
  static const String padres = 'padres';
  static const String chicos = 'chicos';
  
  static String getName(String id) {
    switch (id) {
      case familia: return 'Familia';
      case padres: return 'Padres';
      case chicos: return 'Chicos';
      default: return id;
    }
  }
  
  static String getIcon(String id) {
    switch (id) {
      case familia: return '👨‍👩‍👦‍👦';
      case padres: return '👫';
      case chicos: return '👦👦';
      default: return '👥';
    }
  }
}
