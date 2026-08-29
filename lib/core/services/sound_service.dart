import 'package:audioplayers/audioplayers.dart';

class SoundService {
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
    } catch (_) {}
  }

  Future<void> playReceive() async {
    try {
      await _receivePlayer.stop();
      await _receivePlayer.play(AssetSource('sounds/incoming.aac'));
    } catch (_) {}
  }

  Future<void> playNotification() async {
    try {
      await _receivePlayer.stop();
      await _receivePlayer.play(AssetSource('sounds/notification.wav'));
    } catch (_) {}
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
  }
}
