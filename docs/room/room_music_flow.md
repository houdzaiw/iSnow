# Room Music Flow

## MVVM 与数据

- `music/RoomMusicSheet`、`RoomMusicControls` 只展示 UI，转发用户操作。
- `RoomMusicViewModel` 管理展开/收起、loading、busy、关闭、错误、接管确认与双音量状态。隐藏歌曲列表或收起音乐盒不停止播放；音乐盒右上角关闭会停止并释放占用。
- `RoomMusicRepository.instance` 在应用生命周期内持有曲库和循环模式，按 UID 隔离，重复打开不重复读盘。
- 音乐盒 `isOpened` 由 Repository 按当前房间会话保存在内存，ViewModel 对外提供，与 `expanded` 分开：初次进房为 false，成功展开后为 true；收起、下麦收起及 Keep 不清除，恢复页面仍默认收起。右上角关闭立即清除，即使释放占用失败也不恢复；退出、被踢、切房、重新进房或账号变化清除。状态不持久化，旧房间代次的关闭不能修改新会话或停止新会话的音乐。
- `isOpened` 只控制当前操作者音乐条左侧入口的显示，不同步给同房其他用户；右侧在线列表始终显示并靠右，音乐条高度保持不变。More 的 Music 对房主/管理员始终显示，不受 `isOpened` 限制。首次从 More 打开后音乐条才出现入口，后续可用音乐条重新展开；关闭音乐盒后仍可从 More 再次开启。
- 房间页订阅播放器状态但不主动读盘；首次展开音乐盒或挂载歌曲列表才初始化，复用已有内存数据，不因普通进房触发额外曲库错误提示。列表生命周期持有 ViewModel，避免路由动画期间 autoDispose 后一直 loading。
- Android 的 Add 打开独立 `RoomLocalMusicSheet`，由 `RoomLocalMusicViewModel` 管理权限、扫描、按名称忽略大小写搜索、多选与导入；关闭选择页不停止现有音乐。
- `RoomLocalMusicManager` 通过私有本地插件 `packages/room_music_scan` 查询 Android MediaStore，沿用 Nady 扫描/多选流程。默认筛选大于 100 KB 的 mp3/m4a/aac/wav/ogg/flac/mp4 音频；查询不限制 IS_MUSIC，避免遗漏系统归类为录音的音频。未被系统收录的文件可通过辅助导入选择。
- 仅在用户打开选择页时申请权限：Android 13+ 使用 READ_MEDIA_AUDIO，旧系统使用 READ_EXTERNAL_STORAGE（maxSdkVersion=32）。拒绝时可重新授权，永久拒绝时可前往设置，返回应用重新扫描。不会申请 MANAGE_EXTERNAL_STORAGE 或在启动时读取曲库。
- 扫描和内容 URI 读取在原生工作线程执行；不依赖 MediaStore DATA 绝对路径。选中音频经 ContentResolver 导出到应用临时目录，由 `RoomMusicLibrary` 复制到 Documents 下 `room_music/<uid>/`，SHA-256 去重，SharedPreferences 保存相对文件名。导入完成/取消清理临时文件，删除播放列表曲目不会删除手机原始音频。
- 保留 `file_picker 8.3.7` 作为 Android 的“从文件导入”辅助入口和 iOS 的原有 Add 入口；两种来源共用持久化曲库。时长为可选元数据，旧缓存缺失时默认为 0。
- 添加不会自动播放；单首读取失败不影响其他歌曲保存。列表编辑串行执行，连续点击合并为一次导入，已关闭页面、退房或账号切换后的结果不得提交。导入失败/取消时清理未被播放列表引用的新副本。
- 播放列表支持独立搜索；过滤仅用于展示，播放使用真实歌曲 ID，上一首/下一首和自动续播仍依据完整列表。
- `RoomManager` 管理房间播放器占用和权限；`RoomAgoraManager` 管理真正的共享音频、进度及状态。

## 播放与接口

1. 房主/管理员点击 More 的 Music，关闭 More 面板、激活本机音乐条入口并立即展开居中音乐盒；收起后点击音乐条可以再次展开。打开和浏览曲库不要求上麦。展开不请求 openPlayer，不自动播放；只有实际播放/控制共享混音时才校验上麦。音乐盒通过列表图标打开根导航歌曲面板。未激活时音乐条左侧不渲染音乐胶囊，也没有隐藏点击热区，不隐藏在线列表。
2. Android 扫描本地歌曲、多选并添加，或从文件导入；iOS 保持文件选择器。返回播放器后点击列表项或播放按钮。
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
- 歌曲列表的停止按钮只停止播放，不关闭音乐盒，不清除 `isOpened`；关闭歌曲列表也不清除。被接管或播放失败沿用停止规则，不视为用户主动关闭音乐盒。
- Exit、切房、踢出、退出登录：退房链路等待播放队列和占用关闭，再释放 Agora/socket。服务端关闭失败不阻止其余清理。
- 房间代次与播放器代次隔离异步工作：过期请求不能在退出后重新启动播放。
- 曲库不因退房清空；注销后切换到下一账号的独立曲库。
- 播放失败关闭占用，保留错误供 UI 展示；声音发送失败不能伪装成功。

## UI 资源

以蓝湖 `f2616a5f-f98e-4a45-a1d2-05537e65aa76` 的 `section_30` 为准，音乐盒约 260 x 211，半透明黑底、10px 圆角、白色控件、单行省略歌名。整体在屏幕可见安全区域水平、垂直居中，覆盖展开不挤占麦位/公屏，不再依赖音乐条锚点或麦位数量定位。键盘出现后在键盘上方可见区域重新居中；保留边距并避让底部操作栏，空间不足时等比缩小。无全屏遮罩，外部区域可点击。房间主体不随弹层键盘缩短，避免固定麦位网格溢出。所有视觉尺寸复用 theme token，图标与控件内部样式不变。

控件依次为列表循环/单曲循环/随机、上一首、播放/暂停、下一首、歌曲列表。无歌曲禁用播放/切歌但保留列表入口，准备中显示加载。歌曲列表保留搜索、添加、删除和本地导入，底部仅进度、时间和停止。关闭列表只隐藏列表。

10 张蓝湖图标已下载到 `assets/lanhu/room/`。蓝湖缺失的单曲、随机、停止、删除、搜索按用户授权从 Nady 补齐为同目录下的 5 张 WebP，AppAssets 与 manifest 分别记录两类来源。随机图对应本项目 shuffle；停止使用 Nady 播放器实际“停止并释放占用”的电源图 `room_music_close.webp`，不使用旧版删除叉号 `ic_room_music_close.webp`；搜索和删除沿用 Nady 的白色着色，保留原始文件不改色。播放、停止、删除和搜索行为不变，仍保留 Tooltip/语义。动态滑杆使用真实 Slider，不使用静态截图；多选使用标准 Checkbox 表单控件，不使用 Flutter Icon/Icons。

## 双音量与关闭

- 第一条滑杆控制 Agora 混音本地/房间发布音量（0-100），第二条控制手机系统媒体音量（0-1）。两者独立；实体音量键更新系统滑杆，读取失败时禁用系统滑杆，不伪造音量或强制归零。
- `RoomSystemVolumeManager` 集中持有一个原生监听，多订阅者共享；最后一个观察者释放时注销。展开时读取真实音量，收起/关闭/页面销毁释放监听，不重置手机音量。连续写入合并为最新值，松手最终值仍会提交并回读实际硬件档位。
- 本地 `packages/room_volume_controller` 基于 Nady 的 3.0.0，保留 LICENSE。补齐 Dart await、Android/iOS method result；iOS 音量读取/监听不再改变 AVAudioSession category 或 active，避免影响 Agora。Android 使用 STREAM_MUSIC，监听注册兼容 Android 13+。
- 关闭绕过普通 busy 门禁，立即取消过期播放代次并停止本地混音，再释放服务器占用；准备中关闭、过期文件读取和迟到 SDK 回调均不能重新启动声音。释放接口失败仍保持本地停止并展示错误。
- Keep 后恢复房间默认收起但继续播放；被踢下麦、抢占、Exit 的停止规则保持不变。
- 未上麦用户打开音乐盒后，普通房间状态刷新不会自动收起；仅从“已上麦”变为“未上麦”的下麦状态切换才触发原有收起行为。真正播放仍由 RoomManager 校验麦位，未上麦不得申请播放器占用或发布音频。

## 验收

- 两台真机进同房：一台上麦、添加音频并播放，另一台应能收听；人声闭麦不应停音乐。
- Android 12 和 13+ 分别验证首次授权、拒绝、永久拒绝/设置返回、重新扫描、无歌曲、大小写搜索、多选后切换搜索、长名称以及外部文件辅助导入。
- 检查多首混合成功/失败、重复添加、关闭导入页、导入时退房/切账号、重启后曲库恢复及手机原文件删除后仍可播放沙盒副本。
- 验证暂停/恢复、进度、音量、循环、切歌及两人抢占时确认流程。
- 验证面板关闭和 Keep 后续播，退出/下麦/接管后双方无残留声音。
- 模拟 SDK 与接口测试不能替代真机声学及后台系统测试。

## 本次验证记录（2026-10-25）

- 音乐相关 65 项测试通过：`room_music_test.dart`、`room_music_box_test.dart`、`room_system_volume_test.dart`、`room_local_music_test.dart`、`room_local_music_sheet_test.dart`、`room_music_import_test.dart`。
- 覆盖展开不占用、收起/Keep 续播、准备中关闭、文件读取取消、释放失败本地静音、旧代次抢占确认、双音量独立、写入合并、硬件事件同步和监听释放。320/375/430 宽度截图已核对，长歌名、不同锚点/麦位区域高度和键盘避让无溢出；外部点击可透传。现有本地选择页截图因共用图片按钮结构调整仅更新 1 个抗锯齿像素。
- 资源下载脚本 6 项单测通过；10 张 PNG 可加载，房间资源目录已在 pubspec 声明，没有新增 Flutter Icon/Icons。
- `flutter analyze --no-pub` 和 `git diff --check` 通过。
- `flutter build apk -t lib/lib_dev.dart` 成功，输出 `build/app/outputs/flutter-apk/app-release.apk`。
- 音量插件 Swift 源码通过模拟器 SDK 类型检查；原版 MPVolumeView 的 showsRouteButton/keyWindow 弃用警告仍保留，此检查不是完整 iOS App 构建或真机验证。
- 全量 Flutter 测试 369 通过、1 项既有失败：`login_detail_page_test.dart` 仍期待旧默认区号 `+996`，与本次音乐修改无关，未改动该逻辑。
- 当前未连接 Android 真机，未验证 Android 12/13+、iOS 实际系统音量/实体键、双机同房收听和后台声学效果，仍须按上方验收清单完成；不以模拟测试代替。

## Nady 补图验证

- 五张 WebP 已复制至现有房间资源目录；pubspec 的 `assets/lanhu/room/` 声明已覆盖，无需额外声明或运行时依赖 Nady 路径。
- 新增资源测试验证 AppAssets 不再指向缺省图、资源实际打包和解码成功、SHA-256 与 Nady 原文件一致、manifest 来源完整；单曲/随机切换与搜索/删除白色着色也有界面断言。
- 本次音乐相关 66 项测试与 `flutter analyze --no-pub`、`git diff --check` 通过。新增单曲、随机、歌曲列表截图，并更新本地选择页搜索图标截图，已按 Flutter 实际渲染核对。未改动播放、停止、删除、搜索或模式切换逻辑，没有新增 Flutter Icon/Icons。

## 入口权限修正验证（2026-10-26）

- 新增实际 RoomPage 点击测试：未上麦时音乐条和 More 的 Music 均能展开音乐盒、打开歌曲列表，不弹上麦提示、不请求 openPlayer、不启动混音；普通麦位刷新不误收起，下麦状态切换仍收起。
- 本次入口、音乐播放、闭麦及 Keep/Exit 合并回归 69 项通过，`flutter analyze --no-pub` 与 `git diff --check` 通过。RoomManager 的实际播放上麦校验未放宽。

## 音乐入口方向修正与居中布局（2026-10-27）

- 修正先前方向相反的入口条件：More 的 Music 始终对房主/管理员显示，初次进房隐藏的是音乐条左侧入口。点击 More 后显示入口并立即展开音乐盒；收起、下麦收起、关闭列表、停止播放和 Keep 后重建页面均保留音乐条入口，右上角关闭立即隐藏音乐条入口，More 不受影响。身份变化时 More 权限实时刷新。
- 复用会话测试覆盖被踢、切房、同房重新进入、账号切换、过期代次写入和旧页面关闭；Keep 后新建 ViewModel 保留 `isOpened`、默认收起并继续播放。真实 RoomPage 点击测试覆盖首次从 More 打开、音乐条恢复、关闭后重新开启和角色权限；原生停止/占用失败及准备中关闭继续由真实 Manager 配合模拟 SDK 的测试覆盖。
- 居中布局覆盖 320/375/430 宽度、长歌名、不同麦位数量、键盘、安全区及底栏避让；More 与音乐盒截图按新布局更新。没有新增图片、接口或 Flutter Icon/Icons，不改变 Agora 收听和原生播放流程。真机声学效果仍需按上方验收清单验证。
- 15 个相关测试文件共 151 项回归通过，`flutter analyze --no-pub` 与 `git diff --check` 通过；已核对三种宽度音乐盒、两种宽度 More 及受入口隐藏影响的 Keep/Exit 背景截图。Keep UI 测试沿用实际迷你房间“先 restoreRoom，再打开 RoomPage”的顺序，恢复后音乐条可再次展开音乐盒。
