# iSnow 与 Miloop 的 Android 构建环境

## 本次故障原因

2026-11-11 日志中的首个异常是 `java.io.IOException: No space left on device`。排查时 macOS 数据卷只剩约 4 GiB；后续构建在 Agora AAR 的 JetifyTransform 阶段再次报相同磁盘错误，说明 Kotlin DSL 插件版本提示不是本次故障的根因。退出阶段的缓存锁、daemon registry 锁释放异常属于该失败链路，不能据此判断为项目间版本冲突。

两项目的 Wrapper 独立：iSnow 使用 Gradle 8.12，Miloop 使用 8.14.2，均保持原版本。iSnow 的 AGP、Kotlin 及 Flutter SDK 本次均未升级或修改。Gradle 的版本缓存位于各自的 `caches/<version>`，下载的依赖可以共享；无需为两个项目强行统一版本，也无需新建第二份 GRADLE_USER_HOME 来复制依赖。[Gradle 缓存目录说明](https://docs.gradle.org/current/userguide/directory_layout.html)

## iSnow 的资源限制

该 Mac 有 16 GiB 内存，原 iSnow Gradle 堆上限为 8 GiB、Metaspace 上限为 4 GiB；Miloop Gradle 堆上限约 7.8 GiB。排查时系统已使用约 11.7 GiB 交换空间。这些是资源竞争的证据，堆上限并不等于 JVM 已实际占用的内存。

`android/gradle.properties` 只调整 iSnow：

- Gradle 堆上限 3 GiB、Metaspace 上限 1 GiB、代码缓存上限 256 MiB。
- 最多 2 个 worker，关闭项目并行构建。
- Kotlin daemon 堆上限 1 GiB、Metaspace 上限 512 MiB，避免继续继承过大的 Gradle 配置。
- 保留 AndroidX、Jetifier、Wrapper 版本、签名配置及 API 环境。

限制并发以降低两个项目同时打开时的峰值占用；不调整 Miloop 或用户级 Gradle/JDK 配置。验证进程实际使用 JDK 17 和新的 3 GiB 堆上限。[Gradle 构建环境](https://docs.gradle.org/current/userguide/build_environment.html)、[Kotlin daemon 参数](https://kotlinlang.org/docs/gradle-compilation-and-caches.html)

## 空间恢复与使用方式

本次仅回收可重建内容：未使用的 Gradle 8.8 缓存和发行包、iSnow 的 app intermediates/kotlin/tmp、失败遗留的未完成 transform、未被进程使用的 Android Studio 2024.3 缓存、Gradle 任务结果缓存、iSnow 测试产物及未使用的 CocoaPods 下载缓存，共约 5.3 GiB。清理时保留现有 APK、项目源码、签名文件、Android SDK、已安装的 Pods 和 Miloop 构建目录；随后重新构建更新调试 APK。

清理 iSnow 中间文件前，通过该项目 Wrapper 停止了空闲的 Gradle 8.12；Gradle 8.14.2 进程未停止。不在进程运行时手动删除其 `.lock`、registry 或正在使用的共享缓存。

在各自目录使用自己的 Wrapper；iSnow 仍可通过 IDE 正常运行。使用 ARM64 模拟器或设备时，可以只构建对应 ABI，减少输出和安装占用：

```bash
cd /Users/huili/project/iSnow
/usr/local/flutter/bin/flutter build apk --debug --no-pub --target-platform android-arm64 -t lib/lib_dev.dart
```

输出为 `build/app/outputs/flutter-apk/app-debug.apk`。这里是宿主 Mac 的空间问题；如果之后出现 `INSTALL_FAILED_INSUFFICIENT_STORAGE`，则是 Android 设备／模拟器的数据分区不足，需要单独处理。

## 验证结果

上述 ARM64 调试命令已成功，最后一次增量验证约 30 秒，未再报磁盘写入或锁释放错误。缓存回收量不等于最终磁盘余量：构建会重新生成所需文件，完成时仅剩约 2.1 GiB。建议再腾出至少 10 GiB，作为两项目后续编译、依赖解压和系统交换文件的余量；这不是 Gradle 的硬性最低要求。

生成的 APK 约 204 MiB，只包含 arm64-v8a 原生库；ZIP 完整性和 apksigner 签名校验均通过，`git diff --check HEAD` 通过。

本次未安装、重启或登录设备 App，也未执行 Miloop 的完整构建；Miloop 的 Wrapper、源代码、Gradle 配置和运行中的 8.14.2 进程未修改。
