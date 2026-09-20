package com.example.kuaile_yingyu

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 快乐英语：跟读录音本地归档通道
/// 录音保存在公共下载目录 Download/快乐英语录音/（无需权限，adb 可直接读取，
/// 家长也可在文件管理器里查看/拷贝）。
class MainActivity : FlutterActivity() {
    private val channelName = "kuaile_recordings"
    private val folderName = "快乐英语录音"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveWav" -> {
                        val srcPath = call.argument<String>("srcPath")
                        val fileName = call.argument<String>("fileName")
                        val indexJson = call.argument<String>("indexJson")
                        if (srcPath == null || fileName == null || indexJson == null) {
                            result.error("BAD_ARG", "missing args", null)
                        } else {
                            result.success(saveWav(srcPath, fileName, indexJson))
                        }
                    }
                    "readIndex" -> result.success(readIndex())
                    "clearAll" -> {
                        clearAll()
                        result.success(true)
                    }
                    "stats" -> result.success(stats())
                    else -> result.notImplemented()
                }
            }
    }

    private fun downloadDir(): File {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            folderName
        )
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun saveWav(srcPath: String, fileName: String, indexJson: String): Boolean = try {
        val src = File(srcPath)
        if (!src.exists()) return false
        if (Build.VERSION.SDK_INT >= 29) {
            // Android 10+：MediaStore 写入公共 Download，免权限
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/wav")
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/" + folderName
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return false
            resolver.openOutputStream(uri)?.use { out ->
                src.inputStream().use { it.copyTo(out) }
            } ?: return false
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } else {
            // Android 9-：直接写公共 Download（需要存储权限，无权限时失败由 Dart 端兜底）
            val dest = File(downloadDir(), fileName)
            src.copyTo(dest, overwrite = true)
        }
        // 索引随录音一并更新
        File(downloadDir(), "index.json").writeText(indexJson)
        true
    } catch (e: Exception) {
        false
    }

    private fun readIndex(): String? {
        val f = File(downloadDir(), "index.json")
        return if (f.exists()) f.readText() else null
    }

    private fun clearAll() {
        downloadDir().listFiles()?.forEach { it.delete() }
    }

    private fun stats(): String {
        var count = 0
        var bytes = 0L
        downloadDir().listFiles()?.forEach { f ->
            if (f.isFile && f.name.endsWith(".wav")) {
                count++
                bytes += f.length()
            }
        }
        return "{\"count\":$count,\"bytes\":$bytes}"
    }
}
