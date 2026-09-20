import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';

import 'recordings_store.dart';
import 'scoring.dart';

/// Vosk 跟读打分服务（POC 结论主方案）：
/// 1. 录音（16kHz mono WAV）
/// 2. 同一段 PCM 喂 grammar 识别器 + 自由识别器
/// 3. 混合打分 = (grammar_score + free_score) / 2，五档星级 + APP 三档展示
class SpeechService {
  static VoskFlutterPlugin? _vosk;
  static String? _modelRoot;
  static Model? _loadedModel;

  /// 懒加载模型（只解压一次，ModelLoader 自带缓存）
  static Future<Model> _ensureModel() async {
    if (_loadedModel != null) return _loadedModel!;
    _vosk = VoskFlutterPlugin.instance();
    final loader = ModelLoader();
    _modelRoot = await loader.loadFromAssets(
        'assets/models/vosk-model-small-en-us-0.15.zip');
    _loadedModel = await _vosk!.createModel(_modelRoot!);
    return _loadedModel!;
  }

  /// 开始录音（先请求权限并预留前导缓冲）。成功后由 UI 稍后调 stopAndScore。
  /// [childName]/[bookId]/[itemId] 用于本地归档录音的文件名与索引。
  static Future<bool> startRecording(
    String refText,
    List<String> grammar, {
    String childName = '',
    String bookId = '',
    String itemId = '',
  }) async {
    final recorder = AudioRecorder();
    if (!await recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final wavPath = p.join(dir.path, 'kuaile_rec_${DateTime.now().millisecondsSinceEpoch}.wav');
    try {
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: wavPath,
      );
      await Future.delayed(const Duration(milliseconds: 600)); // 前导缓冲（POC 结论）
      _currentRecorder = recorder;
      _currentWav = wavPath;
      _currentRef = refText;
      _currentGrammar = grammar;
      _currentChild = childName;
      _currentBookId = bookId;
      _currentItemId = itemId;
      return true;
    } catch (e) {
      await recorder.dispose();
      return false;
    }
  }

  static AudioRecorder? _currentRecorder;
  static String? _currentWav;
  static String? _currentRef;
  static List<String> _currentGrammar = const [];
  static String _currentChild = '';
  static String _currentBookId = '';
  static String _currentItemId = '';

  /// 停止录音并打分。录音会本地归档保存（V1.1），不随打分删除。
  static Future<SpeakResult?> stopAndScore() async {
    final recorder = _currentRecorder;
    final wavPath = _currentWav;
    final ref = _currentRef;
    final grammar = _currentGrammar;
    _currentRecorder = null;
    _currentWav = null;
    _currentRef = null;
    _currentGrammar = const [];
    if (recorder == null || wavPath == null || ref == null) return null;

    final path = await recorder.stop();
    await recorder.dispose();
    if (path == null) return null;

    SpeakResult result;
    try {
      final pcm = await _readPcm16FromWav(path);
      if (pcm.length < 1600) {
        // 太短（<0.1s）视为未说话
        result = SpeakResult(
          score: 0, star: 1, displayStars: 1,
          grammarText: '', freeText: '', error: '录音太短，请再试一次',
        );
      } else {
        final model = await _ensureModel();
        final vosk = _vosk!;

        final recGrammar = await vosk.createRecognizer(
          model: model,
          sampleRate: 16000,
          grammar: [...grammar, '[unk]'], // 加 [unk]：非目标内容占位，避免整段被丢弃
        );
        final recFree = await vosk.createRecognizer(
          model: model,
          sampleRate: 16000,
        );
        try {
          // 同一段 PCM 依次喂两个识别器
          final grammarText = await _feedAndGetFinal(recGrammar, pcm);
          final freeText = await _feedAndGetFinal(recFree, pcm);

          final g = coverageScore(ref, grammarText); // 覆盖率主分（修复重复词误判）
          final f = scoreText(ref, freeText).score; // 自由识别参考（童声不可靠，仅兜底）
          // V1.2.1 鼓励式保底：检测到孩子开口（有语音）但两个识别器都没认出来时，
          // 不再给 0 分，给 40 分 + 鼓励语，避免"读了却 0 分"打击学习积极性；
          // 只有确实没听到声音（VAD 判定无语音）才给 0 分。
          final hasVoice = _voiceRatio(pcm) > 0.15;
          double mixed;
          if (g > 0) {
            mixed = g;
          } else if (f > 0) {
            mixed = f;
          } else if (hasVoice) {
            mixed = 40.0;
          } else {
            mixed = 0.0;
          }
          final star = starsFromScore(mixed);
          final display = starsForDisplay(mixed);
          result = SpeakResult(
            score: mixed,
            star: star,
            displayStars: display,
            grammarText: grammarText,
            freeText: freeText,
            error: null,
          );
        } finally {
          await recGrammar.dispose();
          await recFree.dispose();
        }
      }
    } catch (e) {
      result = SpeakResult(
        score: 0, star: 1, displayStars: 1,
        grammarText: '', freeText: '', error: '识别出错：$e',
      );
    }
    // 本地归档（V1.1：录音持久保存，供回听/核对/分析）；失败不影响打分结果
    await _archiveWav(path, result, text: ref);
    return result;
  }

  /// 归档录音：写入公共 Download/快乐英语录音/ 并更新索引；成功后删临时文件
  static Future<void> _archiveWav(String srcPath, SpeakResult result,
      {required String text}) async {
    try {
      final ts = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final stamp = '${ts.year}${two(ts.month)}${two(ts.day)}_'
          '${two(ts.hour)}${two(ts.minute)}${two(ts.second)}';
      final child = _sanitize(_currentChild.isEmpty ? '小朋友' : _currentChild);
      final book = _currentBookId.isEmpty ? 'b0' : _currentBookId;
      final item = _currentItemId.isEmpty ? 'x' : _currentItemId;
      final name = '${child}_${book}_${item}_${result.score.round()}_$stamp.wav';
      final ok = await RecordingsStore.saveWav(
        srcPath: srcPath,
        fileName: name,
        child: child,
        bookId: book,
        itemId: item,
        text: text,
        score: result.score,
        stars: result.star,
      );
      if (ok) {
        final src = File(srcPath);
        if (src.existsSync()) src.deleteSync();
      }
    } catch (_) {
      // 归档失败不阻塞打分结果
    }
  }

  /// 文件名安全化：去除 Windows/Linux 非法字符与空白
  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[\\/:*?"<>|\s]'), '_');

  static Future<String> _feedAndGetFinal(Recognizer rec, Uint8List pcm) async {
    const chunk = 8192;
    for (var pos = 0; pos < pcm.length; pos += chunk) {
      final end = (pos + chunk) < pcm.length ? pos + chunk : pcm.length;
      await rec.acceptWaveformBytes(Uint8List.fromList(pcm.sublist(pos, end)));
    }
    final resultJson = await rec.getFinalResult();
    return _extractText(resultJson);
  }

  static String _extractText(String json) {
    // {"text": "hello world", ...}
    final m = RegExp(r'"text"\s*:\s*"([^"]*)"').firstMatch(json);
    return m?.group(1) ?? '';
  }

  /// 解析 WAV（PCM16 mono）→ 字节流
  static Future<Uint8List> _readPcm16FromWav(String path) async {
    final bytes = await File(path).readAsBytes();
    // 简单 RIFF 解析
    if (bytes.length < 44) return Uint8List(0);
    // data chunk 定位
    var pos = 12;
    while (pos + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(pos, pos + 4));
      final size = bytes[pos + 4] |
          (bytes[pos + 5] << 8) |
          (bytes[pos + 6] << 16) |
          (bytes[pos + 7] << 24);
      if (id == 'data') {
        final dataLen = size < bytes.length - pos - 8 ? size : bytes.length - pos - 8;
        return Uint8List.fromList(bytes.sublist(pos + 8, pos + 8 + dataLen));
      }
      pos += 8 + size + (size & 1);
    }
    return Uint8List(0);
  }

  /// 简单 VAD：16kHz PCM16，20ms 窗能量检测，返回有声帧占比。
  /// 阈值 -40dBFS（≈0.01 幅值），与 POC 童声验证脚本一致。
  static double _voiceRatio(Uint8List pcm) {
    if (pcm.length < 320) return 0;
    const winBytes = 640; // 20ms @16kHz，即 320 个 int16 样本
    var voiced = 0;
    var n = 0;
    final data = ByteData.sublistView(pcm);
    for (var pos = 0; pos + winBytes <= pcm.length; pos += winBytes) {
      var sum = 0.0;
      for (var i = 0; i < winBytes; i += 2) {
        final s = data.getInt16(pos + i, Endian.little) / 32768.0;
        sum += s * s;
      }
      final rms = sum / 320.0;
      if (rms > 0.0001) voiced++; // 0.01^2
      n++;
    }
    return n == 0 ? 0 : voiced / n;
  }

  /// 重置（可选）
  static Future<void> dispose() async {}
}

class SpeakResult {
  final double score; // 0-100
  final int star; // POC 五档
  final int displayStars; // APP 三档（1-3）
  final String grammarText;
  final String freeText;
  final String? error;

  SpeakResult({
    required this.score,
    required this.star,
    required this.displayStars,
    required this.grammarText,
    required this.freeText,
    this.error,
  });

  String get encourageText => encouragement(displayStars);
}
