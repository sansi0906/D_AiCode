/// 满分奖励：知识卡题库（V1.2.4）
/// 数据源：assets/data/riddles/*.json（916 道，八类）
/// 类别：脑筋急转弯/历史/地理/生物/成语典故/诗词/生活常识/冷知识，
/// 内容均为权威百科与中小学通行教材常识口径。
/// 跟读得高分时弹 1 道知识卡；每个跟读项绑定固定一道（一一对应），
/// 已看过的题会去重（ProgressDb.riddles_seen），全部看完一轮后自动重置。
/// V1.3.7（测试审计修复）：由 hash 取模改为确定性排序映射——
/// 全部跟读项 id 排序后与题库按序一一绑定，消除"多题撞一题 / 部分题永不弹出"。
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
Map<String, String>? _itemMap; // itemId -> riddleId（确定性一一映射）

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

/// 收集 content.json 中全部跟读项 id（progressKey 格式：b{bookId}_{itemId}）
Future<List<String>> _collectAllItemIds() async {
  final raw = await rootBundle.loadString('assets/data/content.json');
  final content = jsonDecode(raw) as Map<String, dynamic>;
  final ids = <String>[];
  for (final b in (content['books'] as List<dynamic>? ?? [])) {
    final bm = b as Map<String, dynamic>;
    final bookId = (bm['book_id'] ?? '').toString();
    for (final u in (bm['units'] as List<dynamic>? ?? [])) {
      final um = u as Map<String, dynamic>;
      for (final s in (um['sentences'] as List<dynamic>? ?? [])) {
        ids.add('b${bookId}_${(s as Map)['id']}');
      }
      for (final w in (um['words'] as List<dynamic>? ?? [])) {
        ids.add('b${bookId}_${(w as Map)['id']}');
      }
    }
  }
  ids.sort();
  return ids;
}

/// 构建确定性映射：排序后的第 i 个跟读项 ↔ 第 i % 题数 道知识卡。
/// 排序与题序都稳定，跨运行同一跟读项永远绑定同一道题。
Future<void> _ensureItemMap() async {
  if (_itemMap != null) return;
  final all = await loadRiddles();
  if (all.isEmpty) return;
  final ids = await _collectAllItemIds();
  final map = <String, String>{};
  for (var i = 0; i < ids.length; i++) {
    map[ids[i]] = all[i % all.length]['id']!;
  }
  _itemMap = map;
}

/// 根据跟读项 id 固定绑定一道知识卡（一一对应，跨运行稳定，不重复）
/// V1.3.7：改为异步，先确保映射已构建再查询。
Future<Map<String, String>?> riddleForItem(String itemId) async {
  await _ensureItemMap();
  final map = _itemMap;
  if (map == null) return null;
  final riddleId = map[itemId];
  if (riddleId == null) return null;
  final all = await loadRiddles();
  for (final r in all) {
    if (r['id'] == riddleId) return r;
  }
  return null;
}
