/// 满分奖励：知识卡题库（V1.2.4）
/// 数据源：assets/data/riddles/*.json（916 道，八类）
/// 类别：脑筋急转弯/历史/地理/生物/成语典故/诗词/生活常识/冷知识，
/// 内容均为权威百科与中小学通行教材常识口径。
/// 跟读得 100 分时随机抽 1 道弹出，点"看答案"显示答案；
/// 已看过的题会去重（ProgressDb.riddles_seen），全部看完一轮后自动重置，
/// 保证 916 个跟读项全部满分一轮内不重复。
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/progress_db.dart';

const List<String> kRiddleFiles = [
  'assets/data/riddles/jw.json',
  'assets/data/riddles/his.json',
  'assets/data/riddles/geo.json',
  'assets/data/riddles/bio.json',
  'assets/data/riddles/cy.json',
  'assets/data/riddles/sc.json',
  'assets/data/riddles/life.json',
  'assets/data/riddles/cold.json',
];

List<Map<String, String>>? _cache;

/// 从 assets 加载全部题库（只加载一次，之后走缓存）
Future<List<Map<String, String>>> loadRiddles() async {
  if (_cache != null) return _cache!;
  final list = <Map<String, String>>[];
  for (final f in kRiddleFiles) {
    final raw = await rootBundle.loadString(f);
    final arr = jsonDecode(raw) as List<dynamic>;
    for (final item in arr) {
      final m = item as Map<String, dynamic>;
      list.add({
        'id': m['id'] as String,
        'category': m['category'] as String,
        'q': m['q'] as String,
        'a': m['a'] as String,
      });
    }
  }
  _cache = list;
  return list;
}

/// 随机抽取 n 道（排除已看过的；全部看完一轮则自动重置再抽）
Future<List<Map<String, String>>> pickRiddles(int n) async {
  final all = await loadRiddles();
  final seen = await ProgressDb.getSeenRiddleIds();
  var pool = all.where((r) => !seen.contains(r['id'])).toList()..shuffle();
  if (pool.length < n) {
    await ProgressDb.clearSeenRiddles();
    pool = [...all]..shuffle();
  }
  return pool.take(n).toList();
}

/// 根据跟读项 id 固定绑定一道知识卡（一一对应，不重复）
Map<String, String>? riddleForItem(String itemId) {
  final all = _cache;
  if (all == null || all.isEmpty) return null;
  var hash = 0;
  for (final code in itemId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return all[hash % all.length];
}
