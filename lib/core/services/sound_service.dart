import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  void Function(String sound)? onSoundPlayed;
  final AudioPlayer _sendPlayer = AudioPlayer();
  final AudioPlayer _receivePlayer = AudioPlayer();
  late final AudioPool _keyPressPool;
  late final Future<void> _keyPressPoolReady;

  SoundService() {
    _sendPlayer.setReleaseMode(ReleaseMode.stop);
    _receivePlayer.setReleaseMode(ReleaseMode.stop);

    _keyPressPoolReady = _initializeKeyPressPool();
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

  Future<void> playKeyPress() async {
    try {
      onSoundPlayed?.call('keyPress');

      await _keyPressPoolReady;
      await _keyPressPool.start();
    } catch (_) {}
  }

  Future<void> _initializeKeyPressPool() async {
    _keyPressPool = await AudioPool.create(
      source: AssetSource('sounds/keypress.wav'),
      minPlayers: 4,
      maxPlayers: 12,
    );
  }

  void dispose() {
    _sendPlayer.dispose();
    _receivePlayer.dispose();
    _keyPressPool.dispose();
  }
}
