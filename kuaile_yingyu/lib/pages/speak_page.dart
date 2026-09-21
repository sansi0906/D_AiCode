import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/progress_db.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../services/riddles.dart';
import '../services/scoring.dart';
import '../services/speech_service.dart';
/// 跟读打分：句子/单词列表，点击进入跟读页

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

class SpeakPage extends StatefulWidget {
  final Unit unit;
  final int grade; // 1-6，用于字号/图标分级

  const SpeakPage({super.key, required this.unit, required this.grade});

  @override
  State<SpeakPage> createState() => _SpeakPageState();
}

class _SpeakPageState extends State<SpeakPage> {
  Map<String, dynamic>? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProgressDb.getAll();
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.unit.allItems;
    // 1-2 年级：大尺寸儿童友好；3-6 年级：收紧给文字留宽度
    final lower = widget.grade <= 2;
    final imgSize = lower ? 56.0 : 52.0;
    final txtSize = lower ? 22.0 : 20.0;
    final tagSize = lower ? 17.0 : 16.0;
    final starSize = lower ? 32.0 : 28.0;
    final arrowSize = lower ? 38.0 : 32.0;
    final pad = lower ? 14.0 : 16.0;
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        final r = _progress?[widget.unit.progressKey(it)];
        final stars = (r?['stars'] as int? ?? 0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => SpeakDetailPage(
                      unit: widget.unit, item: it, grade: widget.grade),
                ))
                .then((_) => _load()),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kGreen, width: 2),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      it.imageAsset,
                      width: imgSize,
                      height: imgSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: lower ? 12 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.text,
                            style: TextStyle(
                                fontSize: txtSize, fontWeight: FontWeight.bold, color: kDark)),
                        SizedBox(height: lower ? 3 : 3),
                        Text(it.isWord ? '单词' : '句子',
                            style: TextStyle(
                                fontSize: tagSize, color: const Color(0xFF8A8070))),
                      ],
                    ),
                  ),
                  _StarRow(star5: stars, size: starSize),
                  SizedBox(width: lower ? 2 : 2),
                  Icon(Icons.chevron_right, color: kOrange, size: arrowSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 五档星级显示（已学记录）
class _StarRow extends StatelessWidget {
  final int star5; // 0-5
  final double size;
  const _StarRow({required this.star5, required this.size});

  @override
  Widget build(BuildContext context) {
    if (star5 <= 0) {
      return Icon(Icons.star_border, color: const Color(0xFFD8CFC0), size: size);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          i < star5 ? Icons.star : Icons.star_border,
          color: kYellow,
          size: size,
        ),
      ),
    );
  }
}

/// 跟读页：看图画 → 听示范 → 跟读 → 得分
class SpeakDetailPage extends StatefulWidget {
  final Unit unit;
  final Item item;
  final int grade;

  const SpeakDetailPage(
      {super.key, required this.unit, required this.item, required this.grade});

  @override
  State<SpeakDetailPage> createState() => _SpeakDetailPageState();
}

enum _RecState { idle, recording, scoring }

class _SpeakDetailPageState extends State<SpeakDetailPage> {
  _RecState _state = _RecState.idle;
  SpeakResult? _result;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  /// 满分奖励：每次满分弹出 1 道知识卡（脑筋急转弯/历史/地理/生物/成语典故/
  /// 诗词/生活常识/冷知识，题库 916 道，点"看答案"显示答案，已看过自动去重）
  Future<void> _showRiddleReward() async {
    final riddles = await pickRiddles(1);
    for (var i = 0; i < riddles.length; i++) {
      if (!mounted) return;
      await ProgressDb.markRiddleSeen(riddles[i]['id']!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RiddleDialog(
          index: i + 1,
          total: riddles.length,
          category: riddles[i]['category']!,
          question: riddles[i]['q']!,
          answer: riddles[i]['a']!,
          isLast: i == riddles.length - 1,
        ),
      );
    }
  }

  Future<void> _toggleRecord() async {
    if (_state == _RecState.recording) {
      _stopTimer();
      setState(() => _state = _RecState.scoring);
      final res = await SpeechService.stopAndScore();
      if (!mounted) return;
      setState(() {
        _result = res;
        _state = _RecState.idle;
      });
      if (res != null && res.error == null) {
        await ProgressDb.saveResult(widget.unit.progressKey(widget.item), res.star);
      }
      // V1.2.4 满分奖励：得 100 分弹出 1 道知识卡（题库 916 道不重复）
      if (res != null && res.error == null && res.score >= 85) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showRiddleReward();
        });
      }
    } else {
      await AudioService.stop();
      final child = await ProgressDb.getSetting('child_name', def: '小朋友');
      final ok = await SpeechService.startRecording(
        widget.item.text,
        widget.item.grammarWords,
        childName: child,
        bookId: widget.unit.bookId,
        itemId: widget.item.id,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能跟读')),
        );
        return;
      }
      setState(() {
        _result = null;
        _state = _RecState.recording;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    AudioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('跟读打分',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDark)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 常规高度下学习区在上、操作区在下两端分布；小屏内容超高时可滚动
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ---- 学习区：图 + 词句 + 听示范 ----
                      Column(
                        children: [
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(height: 16),
                          ..._splitSentence(it.text, 38, align: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(it.isWord ? '单词' : '句子',
                              style: const TextStyle(fontSize: 18, color: kDark)),
                          const SizedBox(height: 22),
                          // 听示范（实心绿，与麦克风风格统一）
                          GestureDetector(
                            onTap: () => AudioService.play(it.audioAsset),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: kGreen,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: kGreen.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.volume_up, color: Colors.white, size: 26),
                                  SizedBox(width: 8),
                                  Text('听示范发音',
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ---- 操作区：麦克风 + 状态 + 结果 ----
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _toggleRecord,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _state == _RecState.recording ? kOrange : kGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_state == _RecState.recording ? kOrange : kGreen)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _state == _RecState.recording
                                    ? Icons.stop
                                    : (_state == _RecState.scoring ? Icons.hourglass_top : Icons.mic),
                                color: kWhite,
                                size: 56,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            switch (_state) {
                              _RecState.idle => _result == null ? '点麦克风，大声读出来' : '再来一次，会更棒！',
                              _RecState.recording => '正在录音 ${_elapsed.inSeconds} 秒…点一下结束',
                              _RecState.scoring => '正在打分，请稍候…',
                            },
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 21, color: kDark),
                          ),
                          const SizedBox(height: 14),
                          // 结果展示
                          if (_result != null && _result!.error == null)
                            _ResultCard(result: _result!)
                          else if (_result?.error != null)
                            Text(_result!.error!,
                                style: const TextStyle(fontSize: 20, color: Colors.redAccent)),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RiddleDialog extends StatefulWidget {
  final int index;
  final int total;
  final String category;
  final String question;
  final String answer;
  final bool isLast;

  const _RiddleDialog({
    required this.index,
    required this.total,
    required this.category,
    required this.question,
    required this.answer,
    required this.isLast,
  });

  @override
  State<_RiddleDialog> createState() => _RiddleDialogState();
}

class _RiddleDialogState extends State<_RiddleDialog> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration, color: kOrange, size: 34),
                const SizedBox(width: 8),
                Text('满分奖励 · ${widget.category}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDark)),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(widget.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: kDark)),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showAnswer
                  ? Container(
                      key: const ValueKey('ans'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: kYellow.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('答案：${widget.answer}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kDark)),
                    )
                  : const SizedBox(key: ValueKey('none'), height: 4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAnswer ? kGreen : kOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (_showAnswer) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _showAnswer = true);
                  }
                },
                child: Text(
                  !_showAnswer ? '看答案' : (widget.isLast ? '完成' : '下一题'),
                  style: const TextStyle(fontSize: 24, color: kWhite, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SpeakResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kYellow, width: 3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Icon(
                i < result.displayStars ? Icons.star : Icons.star_border,
                color: kYellow,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // V1.2.1：没听到声音（0 分且无错误）时给明确提示，其余按星级给鼓励语
          Text(result.score <= 0 ? '没听到声音，靠近一点再试试！' : encouragement(result.displayStars),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDark)),
          const SizedBox(height: 4),
          Text('${result.score.toStringAsFixed(0)} 分',
              style: const TextStyle(fontSize: 20, color: kDark)),
        ],
      ),
    );
  }
}
