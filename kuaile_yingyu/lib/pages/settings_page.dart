import 'package:flutter/material.dart';

import '../data/progress_db.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../services/recordings_store.dart';

/// 设置页：孩子昵称、慢速播放、清空进度、录音管理、关于
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _slow = AudioService.slowMode;
  final _nameCtrl = TextEditingController();
  bool _nameLoaded = false;
  ({int count, int bytes}) _recStats = (count: 0, bytes: 0);

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadRecStats();
  }

  Future<void> _loadName() async {
    final name = await ProgressDb.getSetting('child_name', def: '小朋友');
    if (mounted) {
      setState(() {
        _nameCtrl.text = name;
        _nameLoaded = true;
      });
    }
  }

  Future<void> _loadRecStats() async {
    final s = await RecordingsStore.stats();
    if (mounted) setState(() => _recStats = s);
  }

  Future<void> _saveName() async {
    final v = _nameCtrl.text.trim();
    await ProgressDb.setSetting('child_name', v.isEmpty ? '小朋友' : v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('孩子昵称已保存，之后录音会带上这个名字')),
      );
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空进度？', style: TextStyle(fontSize: 26, color: kDark)),
        content: const Text('孩子学过的记录会全部删除，确定吗？',
            style: TextStyle(fontSize: 22, color: kDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(fontSize: 22, color: kDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空', style: TextStyle(fontSize: 22, color: kOrange)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ProgressDb.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('进度已清空')),
        );
      }
    }
  }

  Future<void> _confirmClearRecordings() async {
    final s = _recStats;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空录音？', style: TextStyle(fontSize: 26, color: kDark)),
        content: Text('手机里保存的 ${s.count} 条跟读录音会被删除，删除后无法找回。确定吗？',
            style: const TextStyle(fontSize: 22, color: kDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(fontSize: 22, color: kDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空', style: TextStyle(fontSize: 22, color: kOrange)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await RecordingsStore.clearAll();
      await _loadRecStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音已清空')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('设置',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kDark)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('孩子昵称', style: TextStyle(fontSize: 26, color: kDark)),
                const SizedBox(height: 4),
                const Text('跟读录音会按这个名字分开保存', style: TextStyle(fontSize: 18, color: kDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        enabled: _nameLoaded,
                        style: const TextStyle(fontSize: 22, color: kDark),
                        decoration: InputDecoration(
                          hintText: '如：小明 / 小红',
                          hintStyle: const TextStyle(fontSize: 20, color: Color(0xFFB0A696)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF7F2E8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE8DFCF)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _saveName,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Text('保存', style: TextStyle(fontSize: 20, color: kWhite)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('慢速播放', style: TextStyle(fontSize: 26, color: kDark)),
                      SizedBox(height: 4),
                      Text('0.8 倍速度，适合初学', style: TextStyle(fontSize: 18, color: kDark)),
                    ],
                  ),
                ),
                Switch(
                  value: _slow,
                  activeThumbColor: kGreen,
                  onChanged: (v) {
                    setState(() => _slow = v);
                    AudioService.setSlowMode(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep, color: kOrange, size: 32),
              title: const Text('清空学习进度', style: TextStyle(fontSize: 26, color: kDark)),
              onTap: _confirmClear,
            ),
          ),
          const SizedBox(height: 16),
          _SettingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('跟读录音', style: TextStyle(fontSize: 26, color: kDark)),
                    ),
                    Icon(Icons.mic, color: kGreen, size: 28),
                  ],
                ),
                const SizedBox(height: 4),
                Text('已保存 ${_recStats.count} 条 · ${(_recStats.bytes / 1024 / 1024).toStringAsFixed(1)} MB'
                    '（保存在手机本地，可随时清理）',
                    style: const TextStyle(fontSize: 18, color: kDark)),
                const SizedBox(height: 8),
                if (_recStats.count > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _confirmClearRecordings,
                      icon: const Icon(Icons.delete_outline, size: 22),
                      label: const Text('清空录音', style: TextStyle(fontSize: 20)),
                      style: TextButton.styleFrom(
                        foregroundColor: kOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('关于', style: TextStyle(fontSize: 26, color: kDark)),
                SizedBox(height: 8),
                Text('《快乐英语》自用学习 APP', style: TextStyle(fontSize: 20, color: kDark)),
                Text('教材：新蕾《快乐英语》第1-4册（一、二年级）',
                    style: TextStyle(fontSize: 18, color: kDark)),
                Text('教材：人教精通版第5-12册（三至六年级）',
                    style: TextStyle(fontSize: 18, color: kDark)),
                Text('纯离线 · 无账号 · 无广告 · 不上传任何数据', style: TextStyle(fontSize: 18, color: kDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFCF), width: 2),
      ),
      child: child,
    );
  }
}
