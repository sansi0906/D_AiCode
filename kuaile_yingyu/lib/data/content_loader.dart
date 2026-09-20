import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// 从 assets/data/content.json 加载教材内容（离线、一次加载）。
class ContentLoader {
  static ContentData? _cached;

  static Future<ContentData> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/content.json');
    final data = ContentData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cached = data;
    return data;
  }
}
