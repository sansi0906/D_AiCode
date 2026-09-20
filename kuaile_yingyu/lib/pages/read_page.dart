import 'package:flutter/material.dart';

import '../data/models.dart';
import '../main.dart';
import '../services/audio_service.dart';

/// 课文点读：句子列表，点击播放（配图 + 0.8 倍慢速）

List<Widget> _splitSentence(String text, double fontSize,
    {TextAlign align = TextAlign.start}) {
  // 按句号/问号/感叹号 + 空格断句，每段单独成行，避免单词被拆成单行
  final parts = text.split(RegExp(r'(?<=[.?!])\s+'));
  return List.generate(parts.length, (i) {
    final isLast = i == parts.length - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Text(parts[i],
          textAlign: align,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.bold, color: kDark)),
    );
  });
}

class ReadPage extends StatefulWidget {
  final Unit unit;

  const ReadPage({super.key, required this.unit});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  String? _playingId;

  @override
  void initState() {
    super.initState();
    // 播放完成自动恢复为播放按钮
    AudioService.onComplete = () {
      if (mounted) setState(() => _playingId = null);
    };
  }

  @override
  void dispose() {
    AudioService.onComplete = null;
    AudioService.stop();
    super.dispose();
  }

  Future<void> _toggle(Item item) async {
    if (_playingId == item.id) {
      await AudioService.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    await AudioService.play(item.audioAsset);
    if (mounted) setState(() => _playingId = item.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.unit.sentences;
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        final playing = _playingId == it.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: InkWell(
            onTap: () => _toggle(it),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: playing ? kYellow.withValues(alpha: 0.5) : kWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: playing ? kOrange : const Color(0xFFE8DFCF),
                    width: playing ? 3 : 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部大图：孩子看图学句子
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: const Color(0xFFFFF9EE),
                      child: Image.asset(
                        it.imageAsset,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 句子：按句号/问号/感叹号分段，每段单独成行
                  ..._splitSentence(it.text, 22),
                  const SizedBox(height: 14),
                  // 整行胶囊播放按钮：大而明显，点卡片任意位置都能播
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: playing ? kOrange : kGreen,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (playing ? kOrange : kGreen).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(playing ? Icons.stop_circle : Icons.volume_up,
                            color: kWhite, size: 28),
                        const SizedBox(width: 8),
                        Text(playing ? '正在播放 · 点我停止' : '点我听一听',
                            style: const TextStyle(
                                fontSize: 22, color: kWhite, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
