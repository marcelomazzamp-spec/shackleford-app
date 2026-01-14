import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../utils/constants.dart';

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _soundPlayer = AudioPlayer();
  
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static StreamSubscription? _recordingStream;
  static List<int> _audioBuffer = [];
  
  // ============ INICIALIZACIÓN ============
  
  static Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _soundPlayer.setReleaseMode(ReleaseMode.stop);
  }
  
  static Future<void> dispose() async {
    await stopRecording();
    await stopPlaying();
    await _recorder.dispose();
    await _player.dispose();
    await _soundPlayer.dispose();
  }
  
  // ============ GRABACIÓN ============
  
  static Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }
  
  static Future<bool> startRecording() async {
    if (_isRecording) return false;
    
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;
    
    _audioBuffer = [];
    
    // Configurar grabación
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));
    
    _recordingStream = stream.listen((data) {
      _audioBuffer.addAll(data);
    });
    
    _isRecording = true;
    
    // Vibrar al iniciar
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
    
    return true;
  }
  
  static Future<Uint8List?> stopRecording() async {
    if (!_isRecording) return null;
    
    await _recordingStream?.cancel();
    await _recorder.stop();
    _isRecording = false;
    
    // Vibrar al terminar
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
    
    if (_audioBuffer.isEmpty) return null;
    return Uint8List.fromList(_audioBuffer);
  }
  
  static bool get isRecording => _isRecording;
  
  static int get recordingDuration {
    // PCM 16bit, 16000Hz, mono = 32000 bytes/segundo
    return (_audioBuffer.length / 32000).round();
  }
  
  // ============ REPRODUCCIÓN ============
  
  static Future<void> playAudio(Uint8List audioData) async {
    if (_isPlaying) await stopPlaying();
    
    _isPlaying = true;
    
    // Convertir PCM a formato reproducible
    await _player.play(BytesSource(audioData));
    
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
  }
  
  static Future<void> stopPlaying() async {
    if (!_isPlaying) return;
    await _player.stop();
    _isPlaying = false;
  }
  
  static bool get isPlaying => _isPlaying;
  
  // ============ SONIDOS DEL SISTEMA ============
  
  /// Sonido Nextel al conectar PTT (chirp-chirp)
  static Future<void> playChirpConnect() async {
    await _soundPlayer.play(AssetSource('sounds/nextel_chirp.mp3'));
  }
  
  /// Sonido Nextel al soltar PTT
  static Future<void> playChirpEnd() async {
    await _soundPlayer.play(AssetSource('sounds/nextel_end.mp3'));
  }
  
  /// Sonido de mensaje entrante (beep-beep)
  static Future<void> playIncoming() async {
    await _soundPlayer.play(AssetSource('sounds/nextel_incoming.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }
  
  /// Sonido de alerta urgente
  static Future<void> playAlert() async {
    await _soundPlayer.play(AssetSource('sounds/alert_urgent.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 300, 100, 300, 100, 300]);
    }
  }
  
  /// Sonido de pánico
  static Future<void> playPanicAlarm() async {
    await _soundPlayer.setReleaseMode(ReleaseMode.loop);
    await _soundPlayer.play(AssetSource('sounds/panic_alarm.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500, 200, 500]);
    }
  }
  
  static Future<void> stopPanicAlarm() async {
    await _soundPlayer.stop();
    await _soundPlayer.setReleaseMode(ReleaseMode.stop);
    Vibration.cancel();
  }
  
  /// Click suave
  static Future<void> playClick() async {
    await _soundPlayer.play(AssetSource('sounds/click.mp3'));
  }
}
