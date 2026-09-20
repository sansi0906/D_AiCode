import 'package:flutter/material.dart';

import '../data/models.dart';
import '../main.dart';
import '../services/audio_service.dart';

/// 单词学习：单词卡（大图 + 英文 + 中文 + 发音），左右滑动切换
class WordPage extends StatefulWidget {
  final Unit unit;

  const WordPage({super.key, required this.unit});

  @override
  State<WordPage> createState() => _WordPageState();
}

class _WordPageState extends State<WordPage> {
  final PageController _controller = PageController();
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final words = widget.unit.words;
    if (words.isEmpty) {
      return const Center(
        child: Text('本单元还没有单词', style: TextStyle(fontSize: 24, color: kDark)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: words.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final w = words[i];
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kGreen, width: 3),
                  ),
                  child: Column(
                    children: [
                      // 图片区自适应剩余高度，小屏不溢出
                      Expanded(
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              w.imageAsset,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(w.text,
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold, color: kDark)),
                      const SizedBox(height: 6),
                      Text(w.meaning ?? '',
                          style: const TextStyle(fontSize: 24, color: kDark)),
                      const SizedBox(height: 14),
                      // 喇叭发音 + 戳一戳提示
                      _SpeakerWithHint(
                        onTap: () => AudioService.play(w.audioAsset),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 44, color: kDark),
                onPressed: _index > 0
                    ? () => _controller.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut)
                    : null,
              ),
              Text('${_index + 1} / ${words.length}',
                  style: const TextStyle(fontSize: 24, color: kDark)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 44, color: kDark),
                onPressed: _index < words.length - 1
                    ? () => _controller.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    AudioService.stop();
    super.dispose();
  }
}

/// 喇叭发音按钮 + 浮动"戳一戳"提示气泡（吸引孩子点击）
class _SpeakerWithHint extends StatefulWidget {
  final VoidCallback onTap;
  const _SpeakerWithHint({required this.onTap});

  @override
  State<_SpeakerWithHint> createState() => _SpeakerWithHintState();
}

class _SpeakerWithHintState extends State<_SpeakerWithHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _dy = Tween(begin: -4.0, end: 4.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.volume_up, color: kGreen, size: 72),
          // 浮动提示气泡（右上角）
          Positioned(
            top: -22,
            right: -78,
            child: AnimatedBuilder(
              animation: _dy,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(0, _dy.value), child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Text('戳一戳，听发音',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
          // 气泡小尾巴
          Positioned(
            top: 6,
            right: 22,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 0.78,
                child: Container(width: 12, height: 12, color: kOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
