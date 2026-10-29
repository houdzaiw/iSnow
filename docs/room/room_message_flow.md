# 房间消息与半屏私聊

## 范围与参考

- 房间底栏 `lanhuRoomBottomMessage` 打开半屏消息，不再调用 `toggleVoice()`。
- More 的 Voice、麦克风、公屏输入、音乐和礼物流程不变。
- 参考 Nady：`lib/pages/room/voice_room/widgets/room_chat/nady_conversation_list_in_room_widget.dart`、`lib/pages/p2p_chat/p2p_chat_bottom_sheet.dart`、`lib/pages/p2p_chat/p2p_chat_provider.dart`、`lib/services/api/common_api.dart`。
- 不新增插件，不迁移相册、拍照、转账、专属活动卡片和完整聊天设置。

## 分层与共享

| 层 | 文件 | 职责 |
| --- | --- | --- |
| View | `lib/classes/room/message/room_message_sheet.dart` | 会话列表、刷新、删除确认、打开私聊 |
| View | `lib/classes/room/message/room_private_chat_sheet.dart` | 第二层半屏、返回和所属路由清理 |
| View | `lib/classes/room/message/room_message_frame.dart` | 半屏尺寸、安全区、键盘和图片返回按钮 |
| View | `lib/classes/message/chat_content.dart` | 整页与半屏共享的聊天内容及输入框 |
| ViewModel | `lib/classes/room/message/room_message_view_model.dart` | 房间代次、账号失效、入口防重 |
| ViewModel | `lib/classes/message/message_view_model.dart` | 主消息页与房间共享会话、未读、删除与连接状态 |
| ViewModel | `lib/classes/message/chat_view_model.dart` | 私聊历史分页、实时合并、审核发送与已读 |
| Repository | `lib/classes/message/im_repository.dart` | 现有 HTTP 边界、腾讯 IM 适配与监听释放 |
| Manager | `lib/manager/im_session_manager.dart` | 单一 SDK 登录队列、UID 绑定、连接状态与重连 |
| Model | `lib/model/im_models.dart` | 连接状态、历史分页、系统会话与排序 |

会话列表不建立第二份缓存或 SDK 监听。房间私聊使用独立作用域的现有 `ChatViewModel`，避免关闭半屏时终止另一处整页私聊。历史与实时消息按消息 ID 去重、按时间排序；分页使用最早消息的 `msgID`，单页 20 条。

所有 Nady 请求仍走 `HttpDioManager`，接口路径集中在 `HttpApi`。View 不调用 SDK、HTTP、AuthSession 或数据库。

## 界面与交互

- 根导航打开会话列表，再从根导航叠加私聊；两层均约为屏幕 60% 高，外部遮罩透明。
- 返回或点外部先关闭私聊并回到列表，再关闭列表回房间。关闭动画完成前保留入口锁，避免重复弹层。
- 深色圆角面板；内容底色不透明，避免下层会话文字和房间按钮透出重叠。视觉参数统一在 `lib/theme/`。
- 列表展示头像、昵称、摘要、时间、未读、置顶顺序；下拉刷新，失败可重试；长按确认后才删除。
- 底栏红点来自共享 IM 未读，不取公屏消息数量。仅打开列表不清未读，进入具体会话才标记已读。
- 文本支持发送、实时接收和加载更早历史，保留既有脱敏房间邀请卡片。
- 键盘出现时私聊扩展至键盘上方安全区域，输入栏始终可见；发送失败保留输入，成功才清空。
- System / Wallet Assistant / Friend Assistant / Interaction Notification 对应 UID 10000–10003，只读且无发送输入框。未迁移的消息类型显示类型占位，不暴露原始 JSON。
- 连接中展示进度，错误提供重连，不使用无法关闭的加载弹窗。
- 复用已有图片；缺失资源保留红色占位。不新增 Flutter `Icon` / `Icons.*`。

## 发送契约

1. 确认当前 UID、IM revision、房间代次和视图仍有效，拒绝系统会话发送。
2. 通过现有用户主页接口读取目标 `info.userBaseInfo`。VIP ≥ 5 且非 `FOLLOW_MUTUAL`（或兼容值 3）时，读取 VIP `noDisturb.open`；开启则拒绝发送，权限无法确认也不发送。
3. 请求 `POST /api/shumei/audit`，JSON 为 `{receiveUid, type: "text", content}`。业务成功且 `data == true` 才继续。
4. 创建并发送腾讯 IM 文本消息。每次异步等待后重新检查当前会话；审核拒绝、HTTP 失败或过期均不调用发送。
5. 错误沿用 `userFacingErrorMessage`，服务端优先 `msg`；日志隐藏正文、审核接收 UID 和 TIM 凭证。

## 生命周期

- SDK 登录按当前 UID 合并并发请求；账号变化立即增加 revision，串行登出，旧 token 和异步结果不得登录或回写新账号。
- 会话及消息监听支持释放；晚完成的注册也会移除，不因反复开关面板累积监听。
- 私聊在隐藏、关闭或失效后停止标记已读；重新可见才继续。关闭/账号变化后的审核结果不能继续发送。
- 退出、被踢、切房、退出登录仅移除本功能拥有的弹层，并废弃旧任务。关闭消息本身不调用退房或 Agora。
- **进房时序修复**：`RoomPage` 仅在 `state.isReady` 后订阅消息作用域，避免控制器在 `enterRoom()` 分配新代次前绑定旧代次而永久失效。
- Keep 保持房间连接；恢复后仍可打开消息，不重新创建房间会话。

## 自动化验收（2026-10-29）

| 检查 | 结果 |
| --- | --- |
| `test/im_repository_test.dart` | 20 项通过：并发登录、账号隔离、实时/分页去重、监听清理、审核、VIP、删除与已读 |
| `test/room_message_test.dart` | 14 项通过：进房就绪时序、双层返回、重复点击、只读、草稿、重连、键盘和房间失效 |
| `test/message_pages_test.dart` | 2 项通过：主消息页与整页私聊复用单一登录、只读、审核失败与返回清理 |
| `flutter test --no-pub --reporter=expanded test/room*_test.dart` | 537 项通过，包含 Share、音乐、礼物、Keep/Exit 等既有房间回归 |
| `flutter analyze --no-pub` | 通过 |
| `git diff --check HEAD` | 通过 |

新增 6 张独立基线：`test/goldens/room_message_{inbox,chat}_{320,375,430}.png`。先检查候选图并修复透底重叠，再建立新基线；39 张原有基线 SHA-256 校验一致，未用覆盖旧基线消除差异。

测试用腾讯 SDK 替身，不加载宿主机原生 TIM 库；消息 fixture 使用 `V2TimMessage.fromJson`，避免 SDK 构造函数隐式调用 FFI 时间接口。发送与删除只通过替身验证，不能据此宣称真实后端送达。

## PLL110 真机验收（2026-10-29）

- 用户已允许重新启动调试 App、进入 hei（展示 ID 30317291）以及标记已有会话已读；禁止实际发送或删除。
- 使用设备已安装的 `com.nady.dev1`，未重装、未清数据。旧安装包重启后仍载入旧 Dart 内核，因此 attach 后执行了一次热重启载入完整新代码，随后修复使用热重载。
- 新代码已通过 VM 库清单确认载入。真机发现进房前绑定旧代次的问题，修复后热重载，仅重建过期的消息控制器，没有为此退房或重建 Agora。
- 已确认 hei 中消息按钮打开列表，显示真实 System 会话；仅打开列表保留未读数 1。
- 打开 System 后显示只读历史及安全类型占位，没有输入框或发送操作；返回列表未读数清零，关闭列表后房间底栏红点同步消失。
- 返回流程前后房间代次保持 1，收听及麦克风静音状态均未变化；没有执行真实发送或删除。
- 已验收 Keep 返回 Party、通过 Restore room 恢复 hei，再次打开消息列表成功；未读保持清零，房间代次及音频静音状态不变。
- 当前账号仅有 System 会话，**普通私聊真实键盘、双机收发与真实审核/发送/删除未验收**。普通私聊键盘、小屏、草稿和发送/删除失败由自动化覆盖，不替代原生验收。
- 本地截图：`/tmp/isnow-room-message-inbox-device.png`、`/tmp/isnow-room-message-system-device.png`、`/tmp/isnow-room-message-read-device.png`。截图仅用于本次验收，不作为版本库基线。
