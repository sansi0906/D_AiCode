import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 本地进度存储（SQLite，纯离线）。
/// 表：progress(item_id TEXT PRIMARY KEY, stars INTEGER, done INTEGER, updated TEXT)
class ProgressDb {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'kuaile_progress.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE progress(
            item_id TEXT PRIMARY KEY,
            stars INTEGER NOT NULL DEFAULT 0,
            done INTEGER NOT NULL DEFAULT 0,
            updated TEXT
          )
        ''');
      },
    );
    // 兼容已装设备：settings 表（孩子昵称等）不存在则补建
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    // V1.2.3 满分奖励去重：已出过的知识卡 id
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS riddles_seen(
        riddle_id TEXT PRIMARY KEY,
        seen_at TEXT
      )
    ''');
    // V1.3.4 星级迁移：旧五档归一为三档，从此保存/显示统一用三档
    await _migrateStarsTo3();
    return _db!;
  }

  /// 旧版本把五档 star 存进了 progress 表，导致列表星级虚高。
  /// 一次性迁移：加 star_mode 列，把五档(1-5)归一为三档(1-3)并打标 new3。
  static Future<void> _migrateStarsTo3() async {
    final db = _db!;
    final cols = await db.rawQuery('PRAGMA table_info(progress)');
    final hasMode = cols.any((c) => c['name'] == 'star_mode');
    if (!hasMode) {
      await db.execute('ALTER TABLE progress ADD COLUMN star_mode TEXT DEFAULT "old5"');
      final rows = await db.query('progress', where: "star_mode = 'old5'");
      for (final r in rows) {
        final s = r['stars'] as int;
        final nd = s >= 5 ? 3 : (s >= 3 ? 2 : 1);
        await db.update(
          'progress',
          {'stars': nd, 'star_mode': 'new3'},
          where: 'item_id = ?',
          whereArgs: [r['item_id']],
        );
      }
    }
  }

  /// 读取一条设置；无记录返回 [def]
  static Future<String> getSetting(String key, {String def = ''}) async {
    final db = await _open();
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? def : (rows.first['value'] as String? ?? def);
  }

  /// 写入一条设置
  static Future<void> setSetting(String key, String value) async {
    final db = await _open();
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 保存一次跟读结果；星级 0 表示仅记录"已学"
  /// V1.3.4：统一存三档（1-3），不再存五档
  static Future<void> saveResult(String itemId, int stars) async {
    final db = await _open();
    await db.insert(
      'progress',
      {
        'item_id': itemId,
        'stars': stars,
        'done': 1,
        'updated': DateTime.now().toIso8601String(),
        'star_mode': 'new3',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 读取某条进度；无记录返回 null
  static Future<Map<String, dynamic>?> getResult(String itemId) async {
    final db = await _open();
    final rows = await db.query('progress', where: 'item_id = ?', whereArgs: [itemId]);
    return rows.isEmpty ? null : rows.first;
  }

  /// 批量读取（页面初始化一次拿全）
  static Future<Map<String, dynamic>> getAll() async {
    final db = await _open();
    final rows = await db.query('progress');
    return {for (final r in rows) r['item_id'] as String: r};
  }

  /// 统计某册某单元完成数
  static Future<int> countDoneInUnit(List<String> itemIds) async {
    final all = await getAll();
    return itemIds.where((id) {
      final r = all[id];
      return r != null && (r['done'] as int? ?? 0) == 1;
    }).length;
  }

  /// 清空全部进度
  static Future<void> clearAll() async {
    final db = await _open();
    await db.delete('progress');
  }

  // ---- V1.2.3 满分奖励知识卡去重 ----

  /// 记录一道已出过的知识卡
  static Future<void> markRiddleSeen(String riddleId) async {
    final db = await _open();
    await db.insert(
      'riddles_seen',
      {'riddle_id': riddleId, 'seen_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 已出过的知识卡 id 集合
  static Future<Set<String>> getSeenRiddleIds() async {
    final db = await _open();
    final rows = await db.query('riddles_seen');
    return {for (final r in rows) r['riddle_id'] as String};
  }

  /// 题库看完一轮后重置记录
  static Future<void> clearSeenRiddles() async {
    final db = await _open();
    await db.delete('riddles_seen');
  }
}
