import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/progress_db.dart';
import '../main.dart';
import 'unit_page.dart';

/// 单元列表页：显示 6 个单元卡片 + 完成进度
class BookPage extends StatefulWidget {
  final Book book;
  final VoidCallback onBackHome;

  const BookPage({super.key, required this.book, required this.onBackHome});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  Map<String, dynamic>? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProgressDb.getAll();
    if (mounted) {
      setState(() => _progress = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark, size: 30),
          onPressed: widget.onBackHome,
        ),
        title: Text(widget.book.bookName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kDark)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          ...widget.book.units.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _UnitCard(
                  unit: u,
                  progress: _progress,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) => UnitPage(book: widget.book, unit: u),
                      ))
                      .then((_) => _load()),
                ),
              )),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final Map<String, dynamic>? progress;
  final VoidCallback onTap;

  const _UnitCard({required this.unit, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final itemIds = unit.allItems.map((e) => unit.progressKey(e)).toSet();
    final done = itemIds.isEmpty
        ? 0
        : itemIds.where((id) {
            final r = progress?[id];
            return r != null && (r['done'] as int? ?? 0) == 1;
          }).length;
    final total = itemIds.length;
    final pct = total == 0 ? 0.0 : done / total;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kOrange, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(unit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kDark)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 14,
                backgroundColor: const Color(0xFFEFE7D8),
                color: kGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text('已学 $done / $total 项',
                style: const TextStyle(fontSize: 22, color: kDark)),
          ],
        ),
      ),
    );
  }
}
