# 房间麦克风开闭切换

## 问题与修复

- 原普通构建只从 `AGORA_APPID` 读取 App ID；没有传入时 Agora 未初始化，静音方法直接返回，底栏状态不变。
- `AppEnv` 现使用 Nady 对应环境的公开 App ID；显式进房参数优先，其次 `--dart-define=AGORA_APPID=...`，最后环境默认值。不在客户端放 App Certificate。
- 加入频道仍为 audience，`publishMicrophoneTrack: false`。上麦 API 成功后等待 Agora 初始化和实际入频道回调，再切换 broadcaster、打开麦克风音轨并恢复本地音频流；下麦关闭音轨并恢复 audience。
- 按当前 Nady 实现，开闭麦调用 `muteLocalAudioStream(false)` 和 `muteRecordingSignal(mute)`，只静音采集信号，不主动停止背景音乐混流。

## MVVM 状态链路

`room_bottom_bar.dart` -> `RoomViewModel.toggleLocalMicrophone()` -> `RoomRepository` -> `RoomManager.muteLocalMicrophone()` -> `RoomAgoraManager.muteMicrophone()`。

SDK 调用成功后更新 `RoomAgoraState.mutedMicrophone`，由 Manager listener 同步到 ViewModel，再切换现有图片资源。`RoomPageState.togglingMicrophone` 屏蔽处理中重复点击，不用 Flutter `Icon` / `Icons.*`。

- HTTP 进房成功标准不变，不因等待语音频道阻塞房间页面进入。
- Agora 入频道回调最长等待 15 秒；未初始化、连接失败、超时或静音失败均报告错误，不能静默当作成功，也不能提前改变图标。
- 保留房间或上下麦保留本次会话的静音偏好；Exit 清空偏好，并重置 SDK 的采集静音。没有新增跨启动持久化。
- 异步操作检查房间 ID、engine 和会话代次，退出后的迟到结果不能更新新会话，即使重新进入同一个房间。
- 日志使用 `[RoomAgora] microphone` / `microphone failed`，不打印 token 或认证信息。本地开闭麦不调用管理员禁麦接口。

## 验证

- `test/room_agora_microphone_test.dart`：App ID、音轨发布、采集静音、上下麦保留、Exit 重置、等待频道、失败与同房间重进竞态。
- `test/room_microphone_test.dart`：真实 Manager/Repository/ViewModel 状态同步、初始化中操作、底栏图片双向切换、防重复点击、失败重试及 Keep/恢复。
- 真机仍需两端验收：授予麦克风权限，上麦后远端能听到，闭麦后人声停止、开麦后恢复；有背景音乐时确认闭麦不停止音乐。自动化使用 fake RTC engine，不等同于真实音频验收。
