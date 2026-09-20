import 'package:flutter/material.dart';

import '../data/content_loader.dart';
import '../data/models.dart';
import '../main.dart';
import 'book_page.dart';
import 'settings_page.dart';

/// 首页：年级选择 →（push）册选择 →（push）单元列表
/// 全部用独立路由，Cupertino 边缘滑动返回天然生效。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ContentData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ContentLoader.load();
      if (mounted) {
        setState(() {
          _data = d;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBgColor,
        body: Center(child: CircularProgressIndicator(color: kGreen)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: kBgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: kOrange, size: 64),
                const SizedBox(height: 16),
                const Text('内容加载失败',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kDark)),
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(fontSize: 16, color: kDark),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('重试',
                      style: TextStyle(fontSize: 22, color: kWhite)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;
    final grades = [
      for (final g in data.gradeSupport)
        (g, _gradeName(g), '第 ${_booksLabel(data, g)} 册', _gradeColor(g)),
    ];

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(data.appName,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: kDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: kDark, size: 30),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kYellow.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kYellow.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_emotions,
                    color: kOrange, size: 64),
              ),
              const SizedBox(height: 18),
              const Text('选择年级',
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: kDark)),
              const SizedBox(height: 8),
              const Text('小朋友，今天学几年级呀？',
                  style: TextStyle(fontSize: 22, color: kDark)),
              const SizedBox(height: 28),
              for (final g in grades)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GradeCard(
                    label: g.$2,
                    sub: g.$3,
                    color: g.$4,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            BookSelectorPage(grade: g.$1, data: data),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _gradeName(String g) {
    const names = {
      '1': '一年级',
      '2': '二年级',
      '3': '三年级',
      '4': '四年级',
      '5': '五年级',
      '6': '六年级',
    };
    return names[g] ?? '$g年级';
  }

  static String _booksLabel(ContentData data, String g) {
    final ids = data.booksOfGrade(g).map((b) => b.bookId).toList();
    return ids.isEmpty ? '暂无' : ids.join('、');
  }

  static Color _gradeColor(String g) {
    switch (g) {
      case '1':
        return kGreen;
      case '2':
        return kOrange;
      case '3':
        return const Color(0xFF8FB8E8);
      case '4':
        return const Color(0xFFB39DDB);
      case '5':
        return const Color(0xFFF2A6B8);
      default:
        return const Color(0xFF7FD1C0);
    }
  }
}

/// 册选择页：独立路由，支持边缘滑动返回年级选择
class BookSelectorPage extends StatelessWidget {
  final String grade;
  final ContentData data;

  const BookSelectorPage(
      {super.key, required this.grade, required this.data});

  static const _cnNum = [
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'
  ];

  String _cnBookLabel(String bookId) {
    final n = int.tryParse(bookId);
    if (n != null && n >= 1 && n <= 12) return '第 ${_cnNum[n - 1]} 册';
    return bookId;
  }

  @override
  Widget build(BuildContext context) {
    final books = data.booksOfGrade(grade);
    final gradeName = {
          '1': '一年级',
          '2': '二年级',
          '3': '三年级',
          '4': '四年级',
          '5': '五年级',
          '6': '六年级',
        }[grade] ??
        '$grade年级';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        title: Text('$gradeName · 选择课本',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: kDark)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              for (final b in books)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _BookCard(
                    title: _cnBookLabel(b.bookId),
                    sub: '${b.units.length} 个单元 · ${b.bookNameEn}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookPage(
                          book: b,
                          onBackHome: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_circle_left_outlined,
                      color: kGreen, size: 34),
                  label: const Text('返回选择年级',
                      style: TextStyle(
                          fontSize: 24,
                          color: kDark,
                          fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: const BorderSide(color: kGreen, width: 2),
                    ),
                    backgroundColor: kWhite,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _GradeCard({
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(sub,
                style: const TextStyle(fontSize: 22, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _BookCard({
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGreen, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book, color: kGreen, size: 54),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: kDark)),
                  const SizedBox(height: 6),
                  Text(sub,
                      style: const TextStyle(fontSize: 22, color: kDark)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kOrange, size: 48),
          ],
        ),
      ),
    );
  }
}
