/// 文本比对打分：POC 结论采用的核心算法（与 POC/scripts/scoring.py 一致）
/// norm → 词级 Levenshtein → WER → 0-100 分 → 五档星级
library;

/// 同音/缩略等价组（跟读打分宽容匹配用）
/// 孩子读 "it's a dog"，ASR 可能输出 its / it is / it，都算标准。
const List<Set<String>> _soundGroups = [
  {'it\'s', 'its', 'it', 'is'},
  {'you\'re', 'your', 'you', 'are'},
  {'they\'re', 'their', 'there', 'they', 'are'},
  {'we\'re', 'were', 'we', 'are'},
  {'he\'s', 'his', 'he', 'is'},
  {'she\'s', 'she', 'is'},
  {'who\'s', 'whose', 'who', 'is'},
  {'where\'s', 'where', 'is'},
  {'what\'s', 'what', 'is'},
  {'there\'s', 'there', 'is'},
  {'here\'s', 'here', 'is'},
  {'that\'s', 'thats', 'that', 'is'},
  {'how\'s', 'hows', 'how', 'is'},
  {'mustn\'t', 'mustnt', 'must', 'not'},
  {'i\'m', 'im', 'i', 'am', 'eye'},
  {'i\'ve', 'i', 'have'},
  {'we\'ve', 'we', 'have'},
  {'you\'ve', 'you', 'have'},
  {'they\'ve', 'they', 'have'},
  {'don\'t', 'dont', 'do', 'not'},
  {'doesn\'t', 'doesnt', 'does', 'not'},
  {'can\'t', 'cant', 'can', 'not'},
  {'won\'t', 'wont', 'will', 'not'},
  {'isn\'t', 'isnt', 'is', 'not'},
  {'aren\'t', 'arent', 'are', 'not'},
  {'wasn\'t', 'wasnt', 'was', 'not'},
  {'weren\'t', 'werent', 'were', 'not'},
  {'didn\'t', 'didnt', 'did', 'not'},
  {'couldn\'t', 'couldnt', 'could', 'not'},
  {'wouldn\'t', 'wouldnt', 'would', 'not'},
  {'shouldn\'t', 'shouldnt', 'should', 'not'},
  {'let\'s', 'lets', 'let', 'us'},
  {'i\'ll', 'ill', 'i', 'will'},
  {'you\'ll', 'youll', 'you', 'will'},
  {'we\'ll', 'well', 'we', 'will'},
  {'they\'ll', 'theyll', 'they', 'will'},
  {'he\'ll', 'hell', 'he', 'will'},
  {'she\'ll', 'shell', 'she', 'will'},
  // 小学教材常见同音词（V1.3.5）
  {'to', 'two', 'too'},
  {'for', 'four'},
  {'red', 'read'},
  {'no', 'know'},
  {'nose', 'knows'},
  {'see', 'sea'},
  {'by', 'buy', 'bye'},
  {'our', 'hour'},
  {'one', 'won'},
  {'son', 'sun'},
  {'right', 'write'},
  {'new', 'knew'},
  {'hi', 'high'},
  {'be', 'bee'},
  {'here', 'hear'},
  {'meet', 'meat'},
  {'week', 'weak'},
  {'pair', 'pear'},
  {'blue', 'blew'},
  {'ate', 'eight'},
  // V1.3.5 补扫：题库出现的其余同音/所有格场景
  {'aunt', 'aren\'t', 'arent'},
  {'are', 'our'},
  {'you', 'ewe', 'yew'},
  {'where', 'wear'},
  {'way', 'weigh'},
  {'flower', 'flour'},
  {'wait', 'weight'},
  {'hair', 'hare'},
  {'tail', 'tale'},
  {'plane', 'plain'},
  {'weather', 'whether'},
  {'bear', 'bare'},
  {'break', 'brake'},
  {'morning', 'mourning'},
  {'children\'s', 'children', 'childrens'},
  {'father\'s', 'father', 'fathers'},
  {'mother\'s', 'mother', 'mothers'},
  {'women\'s', 'women', 'womens'},
];

/// 两个词是否发音等价（同组即等价）
bool sameGroup(String a, String b) {
  if (a == b) return true;
  for (final g in _soundGroups) {
    if (g.contains(a) && g.contains(b)) return true;
  }
  return false;
}

/// 返回词所在同音组的全部成员（含自身）；无组则只有自身
Set<String> soundGroupMembers(String w) {
  for (final g in _soundGroups) {
    if (g.contains(w)) return g;
  }
  return {w};
}

/// lowercase + 弯引号归一 + 去标点 + 分词
/// V1.3.5：不再展开缩写，保留原词（it's 保持 it's），
/// 等价匹配交给 sameGroup（it's/its/it is 互相算对）。
List<String> norm(String s) {
  s = s.toLowerCase();
  // 弯引号（教材文本常用 ’ ‘）归一为 ASCII 撇号
  s = s.replaceAll('’', "'").replaceAll('‘', "'");
  s = s.replaceAll(RegExp(r"[^a-z0-9' ]"), ' ');
  return s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
}

/// 词级编辑距离（DP）
int levenshtein(List<String> a, List<String> b) {
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = sameGroup(a[i - 1], b[j - 1]) ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return dp[m][n];
}

/// 词级对齐：返回 ref 每词是否被匹配（读对）
List<bool> levAlign(List<String> ref, List<String> hyp) {
  final m = ref.length, n = hyp.length;
  final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = sameGroup(ref[i - 1], hyp[j - 1]) ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  var i = m, j = n;
  final matched = List<bool>.filled(m, false);
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + (sameGroup(ref[i - 1], hyp[j - 1]) ? 0 : 1)) {
      if (sameGroup(ref[i - 1], hyp[j - 1])) matched[i - 1] = true;
      i--;
      j--;
    } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
      i--;
    } else {
      j--;
    }
  }
  return matched;
}

/// 返回 (分数, 星级, WER, 编辑距离, 目标词数, 识别词数)
({double score, int star, double wer, int dist, int refLen, int hypLen})
    scoreText(String ref, String hyp) {
  final r = norm(ref);
  final h = norm(hyp);
  if (r.isEmpty) {
    return (score: 100.0, star: 5, wer: 0.0, dist: 0, refLen: 0, hypLen: h.length);
  }
  final dist = levenshtein(r, h);
  final wer = dist / r.length;
  final score = (1.0 - wer) * 100.0 < 0 ? 0.0 : (1.0 - wer) * 100.0;
  return (
    score: score,
    star: starsFromScore(score),
    wer: wer,
    dist: dist,
    refLen: r.length,
    hypLen: h.length,
  );
}

/// 覆盖率打分（V1.1.1 修复）：hyp 全局去重后按序匹配 ref 词，
/// 修复 grammar 识别重复词导致严格编辑距离误判 0 分的问题。
/// V1.3.5：匹配用 sameGroup，支持三种情况：
///   1) 吞词：hyp 一个词吃掉 ref 连续多个同组词（we're 吃掉 "we are"）
///   2) 漏读：ref 词没读（跳过最多 2 个不匹配 ref 词继续找）
///   3) 多读：hyp 多出的词直接跳过
/// 完全乱读（[unk] 占位）覆盖率为 0 → 0 分；目标词全部命中 → 100 分。
double coverageScore(String ref, String hyp) {
  final r = norm(ref);
  final h = norm(hyp);
  if (r.isEmpty) return 100.0;
  final uniq = <String>[];
  for (final w in h) {
    if (!uniq.any((u) => sameGroup(u, w))) uniq.add(w);
  }
  var matched = 0;
  var rp = 0;
  var wp = 0;
  while (rp < r.length && wp < uniq.length) {
    final wh = uniq[wp];
    // 1) 优先吞词：wh 与 ref 连续 1-3 个词全部同组
    var consumed = 0;
    for (var k = 3; k >= 1; k--) {
      if (rp + k <= r.length) {
        var allSame = true;
        for (var t = 0; t < k; t++) {
          if (!sameGroup(r[rp + t], wh)) {
            allSame = false;
            break;
          }
        }
        if (allSame) {
          consumed = k;
          break;
        }
      }
    }
    if (consumed > 0) {
      matched += consumed;
      rp += consumed;
      wp++;
      continue;
    }
    // 2) 漏读：wh 与当前 ref 词不同组，允许跳过最多 2 个漏读词再匹配
    var found = false;
    for (var skip = 1; skip <= 2 && rp + skip < r.length; skip++) {
      if (sameGroup(r[rp + skip], wh)) {
        rp += skip; // 跳过的 ref 词视为漏读，不计分
        matched++;
        rp++;
        wp++;
        found = true;
        break;
      }
    }
    if (!found) {
      // 3) 多读/错词：wh 无法匹配，跳过该 hyp 词
      wp++;
    }
  }
  return matched / r.length * 100.0;
}

/// POC 五档映射：>=90 5星；75-89 4星；60-74 3星；45-59 2星；<45 1星
int starsFromScore(double score) {
  if (score >= 90) return 5;
  if (score >= 75) return 4;
  if (score >= 60) return 3;
  if (score >= 45) return 2;
  return 1;
}

/// APP 内展示用简化三档（需求文档：不打击孩子）
int starsForDisplay(double score) {
  if (score >= 85) return 3;
  if (score >= 65) return 2;
  return 1;
}

/// 鼓励语（按星级）
String encouragement(int displayStars) {
  switch (displayStars) {
    case 3:
      return '太棒了！读得非常标准！';
    case 2:
      return '很好！再读一遍会更棒！';
    default:
      return '没关系，听一听再试试！';
  }
}
