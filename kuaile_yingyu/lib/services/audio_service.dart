import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 音频播放封装：点读/单词发音。
/// 慢速模式播放预生成的 _slow 音频（ffmpeg atempo=0.8 变速不变调），
/// 不再用 setPlaybackRate 降速（安卓上会连带降音调，发音怪异）。
class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _slow = true; // 默认慢速

  /// 播放完成回调（UI 据此恢复播放按钮状态）
  static void Function()? onComplete;

  static bool get slowMode => _slow;
  static void setSlowMode(bool v) {
    _slow = v;
  }

  /// 初始化完成监听（进程内只注册一次）
  static bool _listening = false;
  static void _ensureListener() {
    if (_listening) return;
    _listening = true;
    _player.onPlayerComplete.listen((_) => onComplete?.call());
  }

  /// 慢速文件名：xxx.mp3 -> xxx_slow.mp3
  static String _slowPath(String assetPath) =>
      assetPath.replaceFirst('.mp3', '_slow.mp3');

  /// 资产是否存在（用 rootBundle 探测，找不到回退原速文件）
  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> play(String assetPath) async {
    _ensureListener();
    await _player.stop();
    var path = assetPath;
    if (_slow) {
      final slow = _slowPath(assetPath);
      if (await _assetExists(slow)) path = slow;
    }
    await _player.setPlaybackRate(1.0);
    await _player.play(AssetSource(path.replaceFirst('assets/', '')));
  }

  static Future<void> stop() => _player.stop();

  static Future<void> dispose() => _player.dispose();
}
