import 'dart:convert';

import 'package:flutter/services.dart';

/// 跟读录音本地归档（V1.1 新增）
/// 录音与索引保存在公共下载目录 Download/快乐英语录音/
/// （无需权限，adb 可直接读取；家长可在文件管理器查看/拷贝）。
/// 文件名：{昵称}_{bookId}_{itemId}_{分数}_{yyyyMMdd_HHmmss}.wav
class RecordingsStore {
  static const _channel = MethodChannel('kuaile_recordings');

  // V1.3.7：索引"读全量→追加→写回"用 Future 队列串行化，
  // 避免快速连续录音时并发读写导致索引丢失。
  static Future<void> _lock = Future.value();

  static Future<T> _serial<T>(Future<T> Function() f) {
    final p = _lock.then((_) => f());
    _lock = p.then((_) {}, onError: (_) {});
    return p;
  }

  /// 归档一条录音：更新索引后整体写入 Download/快乐英语录音/
  /// [srcPath] 临时 WAV 路径；[fileName] 归档文件名。
  /// 返回是否成功；成功后由调用方删除临时文件。
  static Future<bool> saveWav({
    required String srcPath,
    required String fileName,
    required String child,
    required String bookId,
    required String itemId,
    required String text,
    required double score,
    required int stars,
  }) {
    return _serial(() async {
      try {
        // 读旧索引 → 追加 → 完整写回
        final List<dynamic> list = [];
        final old = await readIndex();
        if (old != null && old.isNotEmpty) {
          try {
            final arr = jsonDecode(old) as List<dynamic>;
            list.addAll(arr);
          } catch (_) {}
        }
        list.add({
          'file': fileName,
          'child': child,
          'book_id': bookId,
          'item_id': itemId,
          'text': text,
          'score': score,
          'stars': stars,
          'ts': DateTime.now().toIso8601String(),
        });
        final indexJson = const JsonEncoder.withIndent('  ').convert(list);
        return await _channel.invokeMethod<bool>('saveWav', {
              'srcPath': srcPath,
              'fileName': fileName,
              'indexJson': indexJson,
            }) ??
            false;
      } catch (_) {
        return false;
      }
    });
  }

  /// 读取索引 JSON 原文（无记录返回 null）
  static Future<String?> readIndex() async {
    try {
      return await _channel.invokeMethod<String>('readIndex');
    } catch (_) {
      return null;
    }
  }

  /// 把某条录音拷贝到 app 缓存目录并返回本地路径（供回听）。
  /// 文件已被自动清理（只保留最高分）时返回 null。
  static Future<String?> copyRecording(String fileName) async {
    try {
      return await _channel.invokeMethod<String>('copyRecording', {
        'fileName': fileName,
      });
    } catch (_) {
      return null;
    }
  }

  /// 清空全部录音与索引
  static Future<void> clearAll() async {
    try {
      await _channel.invokeMethod('clearAll');
    } catch (_) {}
  }

  /// 录音统计：条数 + 占用字节
  static Future<({int count, int bytes})> stats() async {
    try {
      final s = await _channel.invokeMethod<String>('stats');
      if (s == null) return (count: 0, bytes: 0);
      final m = jsonDecode(s) as Map<String, dynamic>;
      return (
        count: m['count'] as int? ?? 0,
        bytes: m['bytes'] as int? ?? 0,
      );
    } catch (_) {
      return (count: 0, bytes: 0);
    }
  }
}
