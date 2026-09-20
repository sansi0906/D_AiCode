import 'package:audioplayers/audioplayers.dart';

/// 音频播放封装：点读/单词发音，支持 0.8 倍慢速（需求固定值）。
class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _slow = true; // 默认 0.8 倍慢速

  /// 播放完成回调（UI 据此恢复播放按钮状态）
  static void Function()? onComplete;

  static bool get slowMode => _slow;
  static void setSlowMode(bool v) {
    _slow = v;
    _player.setPlaybackRate(v ? 0.8 : 1.0);
  }

  /// 初始化完成监听（进程内只注册一次）
  static bool _listening = false;
  static void _ensureListener() {
    if (_listening) return;
    _listening = true;
    _player.onPlayerComplete.listen((_) => onComplete?.call());
  }

  static Future<void> play(String assetPath) async {
    _ensureListener();
    await _player.stop();
    await _player.setPlaybackRate(_slow ? 0.8 : 1.0);
    await _player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
  }

  static Future<void> stop() => _player.stop();

  static Future<void> dispose() => _player.dispose();
}
