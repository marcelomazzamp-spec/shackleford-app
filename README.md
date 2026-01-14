# SHACKLEFORD SECURITY APP

## Protección sin exposición

App móvil para la familia Mazza con funcionalidad Handy (estilo Nextel).

---

## INSTALACIÓN

### Requisitos
- Flutter SDK 3.16+
- Android Studio o VS Code con extensión Flutter
- Un dispositivo Android o emulador

### Pasos

1. **Instalar Flutter** (si no lo tenés):
   ```bash
   # En Windows, descargar de: https://flutter.dev/docs/get-started/install/windows
   # Agregar flutter/bin al PATH
   ```

2. **Clonar/Copiar el proyecto**

3. **Descargar sonidos Nextel**:
   Los archivos de sonido deben estar en `assets/sounds/`:
   - `nextel_chirp.mp3` - Sonido al presionar PTT
   - `nextel_end.mp3` - Sonido al soltar PTT
   - `nextel_incoming.mp3` - Sonido mensaje entrante
   - `alert_urgent.mp3` - Alerta bip-bip
   - `panic_alarm.mp3` - Alarma de pánico
   - `click.mp3` - Click suave

   **Descargalos de:** https://www.zedge.net o https://samplekrate.com buscando "Nextel chirp"

4. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

5. **Compilar APK**:
   ```bash
   flutter build apk --release
   ```

6. **El APK estará en**:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## ESTRUCTURA

```
lib/
├── main.dart              # Punto de entrada
├── models/
│   └── models.dart        # Modelos de datos
├── providers/
│   └── app_provider.dart  # Estado global
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── handy_screen.dart  # Pantalla Nextel
├── services/
│   ├── api_service.dart   # Llamadas HTTP
│   ├── audio_service.dart # Grabación/reproducción
│   ├── handy_service.dart # WebSocket
│   ├── location_service.dart
│   └── storage_service.dart
├── utils/
│   ├── constants.dart     # Configuración
│   └── theme.dart         # Tema oscuro
└── widgets/
    └── widgets.dart       # Componentes UI
```

---

## CONFIGURACIÓN

En `lib/utils/constants.dart` ajustar:

```dart
static const String baseUrl = 'https://TU-SERVIDOR.com';
static const String wsUrl = 'wss://TU-SERVIDOR.com/ws';
```

---

## FUNCIONALIDADES

### Handy (Nextel)
- Push-to-talk individual y grupal
- Sonido chirp clásico al conectar
- Alerta bip-bip (mantener presionado sobre miembro)
- Historial de mensajes

### Ubicación
- Tracking adaptativo (según batería)
- Aprendizaje de rutinas
- Detección de anomalías

### Seguridad
- Botón de pánico
- Código de coacción
- Anti-desinstalación (próximamente)

---

## SERVIDOR

La app se conecta a:
- `https://shak.marcelomazzabureauinmobilario.com/api` - API REST
- `wss://shak.marcelomazzabureauinmobilario.com/ws` - WebSocket

---

## PERMISOS ANDROID

La app requiere:
- `INTERNET` - Conexión
- `RECORD_AUDIO` - Micrófono para PTT
- `ACCESS_FINE_LOCATION` - GPS
- `ACCESS_BACKGROUND_LOCATION` - GPS en background
- `VIBRATE` - Vibración
- `WAKE_LOCK` - Mantener activo
- `RECEIVE_BOOT_COMPLETED` - Iniciar con el sistema

---

## CONTACTO

Shackleford Security - Familia Mazza
