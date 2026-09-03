import 'package:audioplayers/audioplayers.dart';

class SoundService {
  void Function(String sound)? onSoundPlayed;
  final AudioPlayer _sendPlayer = AudioPlayer();
  final AudioPlayer _receivePlayer = AudioPlayer();

  SoundService() {
    _sendPlayer.setReleaseMode(ReleaseMode.stop);
    _receivePlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playSend() async {
    try {
      await _sendPlayer.stop();
      await _sendPlayer.play(AssetSource('sounds/message-sent.wav'));
      onSoundPlayed?.call('send');
    } catch (_) {}
  }

  Future<void> playReceive() async {
    try {
      await _receivePlayer.stop();
      await _receivePlayer.play(AssetSource('sounds/incoming.aac'));
      onSoundPlayed?.call('receive');
    } catch (_) {}
  }

  Future<void> playNotification() async {
    try {
      await _receivePlayer.stop();
      await _receivePlayer.play(AssetSource('sounds/notification.wav'));
      onSoundPlayed?.call('notification');
    } catch (_) {}
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
