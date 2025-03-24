import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  final AudioPlayer _player = AudioPlayer();
  double _volume = 1.0;

  AudioService._internal();

  Future<void> playBackgroundMusic() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/bg_music.mp3'));
      await _player.setVolume(_volume);
      print("Background music started.");
    } catch (e) {
      print("Error playing background music: $e");
    }
  }

  Future<void> stopMusic() async {
    try {
      await _player.stop();
      print("Background music stopped.");
    } catch (e) {
      print("Error stopping background music: $e");
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _player.pause();
      print("Background music paused.");
    } catch (e) {
      print("Error pausing background music: $e");
    }
  }

  Future<void> resumeMusic() async {
    try {
      await _player.resume();
      print("Background music resumed.");
    } catch (e) {
      print("Error resuming background music: $e");
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(_volume);
    print("Volume set to $_volume");
  }

  double getVolume() {
    return _volume;
  }
}
