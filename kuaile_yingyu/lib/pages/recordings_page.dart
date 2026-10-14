import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/audio_service.dart';
import '../services/recordings_store.dart';

/// 录音回听（V1.3.7 测试审计新增）：
/// 列表展示已保存的跟读录音（文本/分数/时间），点击回听。
/// 录音保存在公共下载目录，Android 10+ 通过拷贝到缓存目录后播放。
class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _playingFile;
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await RecordingsStore.readIndex();
    List<Map<String, dynamic>> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final arr = jsonDecode(raw) as List<dynamic>;
        list = arr.map((e) => e as Map<String, dynamic>).toList().reversed.toList();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _entries = list;
        _loading = false;
      });
    }
  }

  /// 回听：拷贝到缓存后播放；文件已被自动清理（每项只留最高分）时提示
  Future<void> _play(Map<String, dynamic> e) async {
    final file = e['file'] as String? ?? '';
    if (file.isEmpty) return;
    AudioService.stop();
    await _player?.dispose();
    _player = null;

    final path = await RecordingsStore.copyRecording(file);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这条录音已被自动清理（每项只保留最高分）')),
      );
      return;
    }
    setState(() => _playingFile = file);
    final p = AudioPlayer();
    _player = p;
    p.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingFile = null);
    });
    try {
      await p.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) setState(() => _playingFile = null);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
    super.dispose();
  }

  String _formatTs(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
    } catch (_) {
      return iso;
    }
  }

  String _scoreText(Map<String, dynamic> e) {
    final s = (e['score'] as num?)?.toDouble();
    return s == null ? '' : '${s.round()} 分';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('录音回听',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kDark)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _entries.isEmpty
              ? const Center(
                  child: Text('还没有跟读录音，先去读几句吧',
                      style: TextStyle(fontSize: 22, color: kDark)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    final playing = _playingFile == e['file'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () => _play(e),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: playing ? kOrange : const Color(0xFFE8DFCF),
                                width: playing ? 3 : 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e['text'] as String? ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: kDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${e['child'] ?? ''} · ${_formatTs(e['ts'] as String? ?? '')}'
                                        '${_scoreText(e).isEmpty ? '' : ' · ${_scoreText(e)}'}',
                                        style: const TextStyle(
                                            fontSize: 18, color: Color(0xFF8A8070))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                playing ? Icons.stop_circle : Icons.play_circle_fill,
                                color: playing ? kOrange : kGreen,
                                size: 46,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
