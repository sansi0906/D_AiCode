/// 文本比对打分：POC 结论采用的核心算法（与 POC/scripts/scoring.py 一致）
/// norm → 词级 Levenshtein → WER → 0-100 分 → 五档星级
library;

const Map<String, String> _contractions = {
  "it's": "it is", "that's": "that is", "what's": "what is", "there's": "there is",
  "here's": "here is", "where's": "where is", "how's": "how is", "who's": "who is",
  "he's": "he is", "she's": "she is", "we're": "we are", "they're": "they are",
  "you're": "you are", "i'm": "i am", "i've": "i have", "we've": "we have",
  "you've": "you have", "they've": "they have", "don't": "do not", "doesn't": "does not",
  "didn't": "did not", "isn't": "is not", "aren't": "are not", "wasn't": "was not",
  "weren't": "were not", "can't": "can not", "couldn't": "could not", "won't": "will not",
  "wouldn't": "would not", "shouldn't": "should not", "let's": "let us", "i'll": "i will",
  "you'll": "you will", "we'll": "we will", "they'll": "they will",
};

/// lowercase + 弯引号归一 + 缩写展开 + 去标点 + 分词
List<String> norm(String s) {
  s = s.toLowerCase();
  // 弯引号（教材文本常用 ’ ‘）归一为 ASCII 撇号，否则缩写展开失效
  s = s.replaceAll('’', "'").replaceAll('‘', "'");
  s = s.replaceAll(RegExp(r"[^a-z0-9' ]"), ' ');
  final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final out = <String>[];
  for (final w in words) {
    if (_contractions.containsKey(w)) {
      out.addAll(_contractions[w]!.split(' '));
    } else {
      out.add(w);
    }
  }
  return out;
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
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
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
      final cost = ref[i - 1] == hyp[j - 1] ? 0 : 1;
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
    if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + (ref[i - 1] == hyp[j - 1] ? 0 : 1)) {
      if (ref[i - 1] == hyp[j - 1]) matched[i - 1] = true;
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
/// 完全乱读（[unk] 占位）覆盖率为 0 → 0 分；目标词全部命中 → 100 分。
double coverageScore(String ref, String hyp) {
  final r = norm(ref);
  final h = norm(hyp);
  if (r.isEmpty) return 100.0;
  final uniq = <String>[];
  for (final w in h) {
    if (!uniq.contains(w)) uniq.add(w);
  }
  var matched = 0;
  var p = 0;
  for (final w in r) {
    final idx = uniq.indexOf(w, p);
    if (idx >= 0) {
      matched++;
      p = idx + 1;
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
  if (score >= 75) return 3;
  if (score >= 60) return 2;
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
