import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;
  RingtoneService._internal();

  static const platform = MethodChannel('com.example.app/ringtone');
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // 🔔 Play native ringtone - MAIN METHOD
  Future<void> playNativeRingtone({required bool isIncoming}) async {
    if (_isPlaying) {
      print('⚠️ Ringtone already playing');
      return;
    }
    try {
      _isPlaying = true;

      // Call Android native code to play ringtone
      await platform.invokeMethod('playRingtone', {
        'type': isIncoming ? 'incoming' : 'outgoing',
      });

      print(
        '🔔 Playing native ringtone: ${isIncoming ? "incoming" : "outgoing"}',
      );
    } on PlatformException catch (e) {
      print('❌ Error playing native ringtone: ${e.message}');
      // Fallback to audio player
      await _playFallbackRingtone(isIncoming);
    } catch (e) {
      print('❌ Unexpected error: $e');
      await _playFallbackRingtone(isIncoming);
    }
  }

  // 🔊 Fallback method using audioplayers package
  Future<void> _playFallbackRingtone(bool isIncoming) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      if (isIncoming) {
        await _audioPlayer.play(AssetSource('sounds/incoming_call.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/outgoing_call.mp3'));
      }

      print('🔊 Playing fallback ringtone');
    } catch (e) {
      print('❌ Fallback ringtone error: $e');
      print('⚠️ Make sure audio files exist in assets/sounds/');
    }
  }

  // 🛑 Stop ringtone
  Future<void> stopRingtone() async {
    if (!_isPlaying) {
      print('⚠️ No ringtone playing');
      return;
    }

    try {
      // Stop native ringtone
      await platform.invokeMethod('stopRingtone');

      // Stop audio player (fallback)
      await _audioPlayer.stop();

      _isPlaying = false;
      print('🛑 Ringtone stopped');
    } catch (e) {
      print('❌ Error stopping ringtone: $e');

      // Force stop
      try {
        await _audioPlayer.stop();
        _isPlaying = false;
      } catch (e2) {
        print('❌ Force stop failed: $e2');
      }
    }
  }

  // 📳 Vibrate (optional - already handled in MainActivity)
  Future<void> vibrate() async {
    try {
      await platform.invokeMethod('vibrate');
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  // 📊 Check if playing
  bool get isPlaying => _isPlaying;

  // 🧹 Dispose
  void dispose() {
    stopRingtone();
    _audioPlayer.dispose();
  }
}
