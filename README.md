# 快乐英语（小学英语学习 App）

专为 1-6 年级孩子设计的离线英语学习 App，对齐天津地区教材（新蕾版 1-2 年级 / 人教精通版 3-6 年级）。Flutter 开发，纯本地运行，无网络、无广告、无账号。

## 功能

- **课文点读**：按单元展示课文句子，点按钮听标准发音
- **单词学习**：大图 + 单词 + 中文释义，喇叭按钮发音
- **跟读打分**：孩子对着麦克风读，本地 sherpa-onnx 语音识别 + 词级比对打分（0-100 分 + 星级）
- **满分知识卡**：跟读 100 分弹出一道小知识（脑筋急转弯 / 历史 / 地理 / 生物 / 成语 / 诗词 / 生活常识 / 冷知识，共 916 道）
- **进度本地保存**：SQLite 记录每一项的星级和是否已学

## 内容

- 12 册教材（book1-12），共 916 个跟读项（单词 + 句子）
- 教材标准：天津北辰区现行小学英语教材
- 素材：标准女声发音音频 + 对应插图，全部离线打包

## 目录结构

```
kuaile_yingyu/          # Flutter 工程
  lib/
    pages/              # 页面：年级选择/册选择/单元/课文点读/单词/跟读/设置
    services/           # 音频播放/打分/语音识别/知识卡
    data/               # 数据模型/进度数据库/内容加载
  assets/
    data/content.json   # 教材内容（12 册）
    data/riddles/       # 916 道知识卡 JSON
    audio/              # 标准发音音频
    images/             # 插图
需求文档/                # 产品需求文档
```

## 构建

环境：Flutter 3.x + Android SDK。

```bash
cd kuaile_yingyu
flutter pub get
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

安卓 64 位（arm64-v8a），最低支持 Android 8.0。APK 体积约 700MB（含离线语音模型 + 全部音频图片素材）。

## 最新版本

当前版本 V1.2.16。最新 APK 见 [Releases](https://github.com/sansi0906/D_AiCode/releases)。

## 隐私

- 纯离线运行，不收集任何数据
- 孩子录音仅保存在本机 App 私有目录，不上传
- 无账号、无广告、无追踪
