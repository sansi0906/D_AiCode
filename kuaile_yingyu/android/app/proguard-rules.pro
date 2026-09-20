# Vosk/JNA 保留规则：JNA 依赖运行时反射（Pointer.peer 等字段），混淆会破坏其加载
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { *; }
-keep class org.vosk.** { *; }
-keepclassmembers class org.vosk.** { *; }
