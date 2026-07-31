import 'package:audioplayers/audioplayers.dart';

/// Plays one local voice-note file at a time.
class VoicePlayer {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  void dispose() => _player.dispose();
}
