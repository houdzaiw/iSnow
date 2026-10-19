# Room Music Flow

## MVVM 与数据

- `music/RoomMusicSheet`、`RoomMusicControls` 只展示 UI，转发用户操作。
- `RoomMusicViewModel` 管理 loading、busy、错误及接管确认；关闭面板不停止播放。
- `RoomMusicRepository.instance` 在应用生命周期内持有曲库和循环模式，按 UID 隔离，重复打开不重复读盘。
- `RoomMusicLibrary` 使用与 Nady 相同版本的 `file_picker 8.3.7` 选择本地音频；复制到应用 Documents 下 `room_music/<uid>/`，SHA-256 去重，SharedPreferences 保存相对文件名。不会依赖外部文件临时授权或 iOS 容器绝对路径。
- `RoomManager` 管理房间播放器占用和权限；`RoomAgoraManager` 管理真正的共享音频、进度及状态。

## 播放与接口

1. 音乐条或 More 的 Music 入口打开根导航底部面板；按 Nady 规则，必须已上麦。
2. 添加本地歌曲，点击列表项或播放按钮。
3. 未占用播放器时，POST `/api/room/openPlayer`，参数 `roomId` 为当前服务端真实 ID，`opType: 1`。
4. `code=4062` 展示服务端冲突提示，仅用户确认后重试 `opType: 2`；取消不播放、不强抢。
5. 等 Agora 连接成功后恢复 Broadcaster/音频发布，`startAudioMixing(loopback: false, cycle: 1)`，整个房间都能听到。保留用户 `mutedMicrophone`，不自动打开人声。
6. SDK 回调确认 Playing/Paused/Failed；每秒查询时长和进度。调用 pause/resume、seek 及混音本地/发布音量接口。重复启动至少间隔 550 ms。
7. 一首播完后，应用级 Repository 按列表循环、单曲循环或随机模式续播，面板关闭也有效。
8. 房主/管理员沿用 Nady POST `/api/room/msg/push`，`event: RoomMusicPlaybackStatusEvent`、`data: PLAYING/PAUSED/STOPPED/FAILED`。不臆造服务端不支持的歌曲标题消息。听众通过 Agora 已有订阅收听。
9. 开启音乐控制时额外订阅 `global:<uid>`，仅处理与房间相关的 `RoomClosePlayerEvent`。被强制接管后立即停止本地混音，不调用 closePlayer 释放别人的占用。

## 生命周期与错误

- 隐藏音乐面板或 Keep：保持 socket、Agora、播放和进度计时器；恢复房间后音乐条显示真实歌曲名称。
- 停止按钮、删除当前曲目、下麦或被踢下麦：停止混音，并 POST `/api/room/closePlayer`（只传 roomId）。
- Exit、切房、踢出、退出登录：退房链路等待播放队列和占用关闭，再释放 Agora/socket。服务端关闭失败不阻止其余清理。
- 房间代次与播放器代次隔离异步工作：过期请求不能在退出后重新启动播放。
- 曲库不因退房清空；注销后切换到下一账号的独立曲库。
- 播放失败关闭占用，保留错误供 UI 展示；声音发送失败不能伪装成功。

## UI 资源

现有 Lanhu 音乐图用于入口及曲目。播放、暂停、上一首、下一首、停止、删除、音量未提供对应设计稿切图，统一使用红色缺省图，并在 `lanhu_room_assets_manifest.json` 中标注。按钮带语义和 Tooltip；后续补图只替换 AppAssets 映射，不使用 Flutter Icon/Icons。

## 验收

- 两台真机进同房：一台上麦、添加音频并播放，另一台应能收听；人声闭麦不应停音乐。
- 验证暂停/恢复、进度、音量、循环、切歌及两人抢占时确认流程。
- 验证面板关闭和 Keep 后续播，退出/下麦/接管后双方无残留声音。
- 模拟 SDK 与接口测试不能替代真机声学及后台系统测试。
