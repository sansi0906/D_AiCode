import 'package:flutter/material.dart';

import '../data/models.dart';
import '../main.dart';
import 'read_page.dart';
import 'speak_page.dart';
import 'word_page.dart';

/// 单元内容页：三个入口 Tab（课文点读 / 单词学习 / 跟读打分）
class UnitPage extends StatefulWidget {
  final Book book;
  final Unit unit;

  const UnitPage({super.key, required this.book, required this.unit});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          backgroundColor: kBgColor,
          elevation: 0,
          title: Text(widget.unit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDark)),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: kGreen,
            unselectedLabelColor: kDark,
            indicatorColor: kGreen,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: '课文点读'),
              Tab(text: '单词学习'),
              Tab(text: '跟读打分'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReadPage(unit: widget.unit),
            WordPage(unit: widget.unit),
            SpeakPage(unit: widget.unit, grade: int.parse(widget.book.grade)),
          ],
        ),
      ),
    );
  }
}
