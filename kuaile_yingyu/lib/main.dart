import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'pages/home_page.dart';
import 'services/audio_service.dart';

/// 主题色板（UI 设计规范 V1.0）
const kBgColor = Color(0xFFFFF9EE); // 米白背景
const kGreen = Color(0xFF8FD18A); // 主绿
const kOrange = Color(0xFFFFB35C); // 橙
const kYellow = Color(0xFFFFD166); // 黄
const kDark = Color(0xFF4A4A4A); // 深灰文字
const kWhite = Color(0xFFFFFFFF);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KuaileApp());
}

class KuaileApp extends StatelessWidget {
  const KuaileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '快乐英语',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBgColor,
        // 安卓也支持 iOS 风格的左边缘滑动返回
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kGreen,
          primary: kGreen,
          secondary: kOrange,
        ),
        fontFamily: 'sans-serif',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 46, fontWeight: FontWeight.bold, color: kDark),
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: kDark),
          titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: kDark),
          bodyLarge: TextStyle(fontSize: 24, color: kDark),
          bodyMedium: TextStyle(fontSize: 22, color: kDark),
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// 统一的"回到主页"动作：停止播放
void backToHome(BuildContext context) {
  AudioService.stop();
  Navigator.of(context).popUntil((r) => r.isFirst);
}
