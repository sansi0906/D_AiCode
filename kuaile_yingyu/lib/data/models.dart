import '../services/scoring.dart';

/// 数据模型：Book / Unit / Item（句子或单词）
/// 与 assets/data/content.json 的结构一一对应。
class Item {
  final String id;
  final String text;
  final String audio;
  final String image;
  final String imageDesc;
  final String? meaning; // 单词中文释义（句子为 null）
  final bool isWord; // false=句子, true=单词

  Item({
    required this.id,
    required this.text,
    required this.audio,
    required this.image,
    required this.imageDesc,
    required this.isWord,
    this.meaning,
  });

  factory Item.fromJson(Map<String, dynamic> j, {required bool isWord}) {
    return Item(
      id: j['id'] as String? ?? '',
      text: j['text'] as String? ?? '',
      audio: j['audio'] as String? ?? '',
      image: j['image'] as String? ?? '',
      imageDesc: j['image_desc'] as String? ?? '',
      meaning: j['meaning'] as String?,
      isWord: isWord,
    );
  }

  /// assets 前缀路径
  String get audioAsset => 'assets/audio/$audio';
  String get imageAsset => 'assets/images/$image';

  /// 语法词典：跟读打分 grammar 约束用（norm 展开：I'm→i am，引号归一）
  /// 必须用展开后的词，否则 Vosk grammar 词表里没有 am，读得标准也拿不到满分
  List<String> get grammarWords => norm(text);
}

class Unit {
  final String unitId;
  final String title;
  final String titleEn;
  final String bookId; // 所属册（进度 key 防串册）
  final List<Item> sentences;
  final List<Item> words;

  Unit({
    required this.unitId,
    required this.title,
    required this.titleEn,
    required this.bookId,
    required this.sentences,
    required this.words,
  });

  factory Unit.fromJson(Map<String, dynamic> j, {String bookId = ''}) {
    final ss = (j['sentences'] as List<dynamic>? ?? [])
        .map((e) => Item.fromJson(e as Map<String, dynamic>, isWord: false))
        .toList();
    final ws = (j['words'] as List<dynamic>? ?? [])
        .map((e) => Item.fromJson(e as Map<String, dynamic>, isWord: true))
        .toList();
    return Unit(
      unitId: (j['unit_id'] ?? '').toString(),
      title: j['title'] as String? ?? '',
      titleEn: j['title_en'] as String? ?? '',
      bookId: bookId,
      sentences: ss,
      words: ws,
    );
  }

  List<Item> get allItems => [...sentences, ...words];

  /// 进度唯一 key（带册前缀，避免不同册 U1 串进度）
  String progressKey(Item item) => 'b${bookId}_${item.id}';
}

class Book {
  final String bookId;
  final String bookName;
  final String bookNameEn;
  final String grade;
  final List<Unit> units;

  Book({
    required this.bookId,
    required this.bookName,
    required this.bookNameEn,
    required this.grade,
    required this.units,
  });

  factory Book.fromJson(Map<String, dynamic> j) {
    return Book(
      bookId: (j['book_id'] ?? '').toString(),
      bookName: j['book_name'] as String? ?? '',
      bookNameEn: j['book_name_en'] as String? ?? '',
      grade: (j['grade'] ?? '').toString(),
      units: (j['units'] as List<dynamic>? ?? [])
          .map((e) => Unit.fromJson(e as Map<String, dynamic>,
              bookId: (j['book_id'] ?? '').toString()))
          .toList(),
    );
  }
}

class ContentData {
  final String appName;
  final List<String> gradeSupport;
  final String textbook;
  final String version;
  final List<Book> books;

  ContentData({
    required this.appName,
    required this.gradeSupport,
    required this.textbook,
    required this.version,
    required this.books,
  });

  factory ContentData.fromJson(Map<String, dynamic> j) {
    return ContentData(
      appName: j['app_name'] as String? ?? '',
      gradeSupport: (j['grade_support'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      textbook: j['textbook'] as String? ?? '',
      version: j['version'] as String? ?? '',
      books: (j['books'] as List<dynamic>? ?? [])
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 按年级取册：grade 传 '1' / '2'
  List<Book> booksOfGrade(String grade) =>
      books.where((b) => b.grade == grade).toList();
}
