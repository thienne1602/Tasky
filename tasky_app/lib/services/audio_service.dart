import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  bool _isBackgroundMusicEnabled = false;
  bool _isSoundEffectsEnabled = true;

  // Sound effect paths
  // NOTE: keep file names ASCII to avoid issues on Windows paths
  static const String _taskCompleteSound = 'audio/task_complete.mp3';
  static const String _deadlineAlertSound = 'audio/deadline.mp3';
  static const String _notificationSound = 'audio/notification.mp3';

  // Background music paths
  static const List<String> _backgroundMusic = [
    'audio/bgm1.mp3',
    'audio/bgm2.mp3',
    'audio/bgm3.mp3',
  ];

  int _currentBackgroundTrack = 0;

  // Settings
  void setSoundEffectsEnabled(bool enabled) {
    _isSoundEffectsEnabled = enabled;
  }

  void setBackgroundMusicEnabled(bool enabled) {
    _isBackgroundMusicEnabled = enabled;
    if (!enabled) {
      _backgroundPlayer.stop();
    }
  }

  bool get isSoundEffectsEnabled => _isSoundEffectsEnabled;
  bool get isBackgroundMusicEnabled => _isBackgroundMusicEnabled;

  // Sound effects
  Future<void> playTaskCompleteSound() async {
    if (!_isSoundEffectsEnabled) return;
    try {
      print('Playing task complete sound: $_taskCompleteSound');
      await _audioPlayer.play(AssetSource(_taskCompleteSound));
    } catch (e) {
      print('Error playing task complete sound: $e');
      // Try fallback without assets prefix
      try {
        final fallbackPath = _taskCompleteSound.replaceFirst('assets/', '');
        await _audioPlayer.play(AssetSource(fallbackPath));
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
      }
    }
  }

  Future<void> playDeadlineAlertSound() async {
    if (!_isSoundEffectsEnabled) return;
    try {
      await _audioPlayer.play(AssetSource(_deadlineAlertSound));
    } catch (e) {
      print('Error playing deadline alert sound: $e');
    }
  }

  Future<void> playNotificationSound() async {
    if (!_isSoundEffectsEnabled) return;
    try {
      await _audioPlayer.play(AssetSource(_notificationSound));
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  // Background music
  Future<void> playBackgroundMusic() async {
    if (!_isBackgroundMusicEnabled) return;
    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer
          .play(AssetSource(_backgroundMusic[_currentBackgroundTrack]));
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  Future<void> nextBackgroundTrack() async {
    if (!_isBackgroundMusicEnabled) return;
    _currentBackgroundTrack =
        (_currentBackgroundTrack + 1) % _backgroundMusic.length;
    await playBackgroundMusic();
  }

  Future<void> previousBackgroundTrack() async {
    if (!_isBackgroundMusicEnabled) return;
    _currentBackgroundTrack = _currentBackgroundTrack > 0
        ? _currentBackgroundTrack - 1
        : _backgroundMusic.length - 1;
    await playBackgroundMusic();
  }

  // Get current track info
  String getCurrentTrackName() {
    return _backgroundMusic[_currentBackgroundTrack]
        .split('/')
        .last
        .replaceAll('.mp3', '')
        .toUpperCase();
  }

  // Cleanup
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _backgroundPlayer.dispose();
  }
}
