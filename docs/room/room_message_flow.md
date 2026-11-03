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

## 会话摘要修复（2026-11-03）

- 主消息页和房间内会话列表统一使用 `imConversationPreview()`，传入会话、当前 IM 账号 UID、界面语言，返回 `ImConversationPreview`（实际文本或本地化文案键）。View 仅渲染结果，不解析 JSON。
- `ImCustomMessageEnvelope` 兼容外层和 payload 的 Map/JSON 字符串，严格只提取 Nady 已确认的字段。损坏或未知数据不展示原始 JSON、`desc` 或其他私有字段，也不无依据提示升级。
- 普通消息的 `TextIMMsg` 使用 `text`；转账使用 `titleEn/titleAr/titleTr/titleId`；`SystemComplexIMMsg` 和 `InviteAcceptedPrivateComplexMsg` 使用 `textMap`。分享、赠礼方向、币种、代理/主播/BD 邀请等使用对应的本地化业务摘要。
- 系统 UID 10000–10003 使用 Nady 的系统会话规则：钱包的 `title/titleAr/...`、奖励包的 `enTitle/arTitle/...`、复杂通知/VIP/邀请成功的 `titleMap`；互动通知按评论/回复/@/点赞展示。没有标题的好友激活通知沿用 Nady 的 event 文案。
- 多语言优先当前语言，空缺或错误类型回退英文；仍无内容时使用相应类型提示。未知普通消息显示“不支持的消息”，未知系统通知显示“你有一条新消息”；只有真实空文本或没有最后一条消息时显示“暂无消息内容”。
- 摘要单行化不修改 SDK 原文；图片、语音、视频、文件、位置、表情、群通知、聊天记录均有明确的本地化摘要。
- **边界**：保留聊天正文 `imMessagePreview()` 的签名和行为，未迁移系统通知卡片、跳转或活动功能。SDK 监听、排序、已读、删除和接口不变，不持久化已翻译摘要，语言切换和实时更新会重新生成。
- 参考 Nady `ConversationList.getLastMessageShowText()` 和 `NadySystemMsgModel.getLatestSystemMessage()`。测试使用脱敏协议样例，不代表已取得本次异常会话的真实 payload；未实际发送或删除消息。
- 测试：`im_conversation_preview_test.dart` 覆盖普通/系统类型、双层 JSON、语言回退、账号方向、媒体、错误和正文兼容；两处列表在 320/375/430 宽度验证长摘要、实时更新、语言切换、刷新和未读数，沿用旧截图基线。
- 验证结果：新增 100 项摘要单元测试、6 项列表界面用例；连同既有消息测试共 142 项通过。完整房间回归 559 项通过，`flutter analyze --no-pub`、`git diff --check HEAD` 及 `git diff --exit-code HEAD -- test/goldens` 均通过。

## 系统消息图文详情（2026-11-03）

### 入口与分层

- 系统 UID 10000–10003 从主消息页进入 `SystemMessagePage`，从房间消息列表进入原半屏容器；两处均通过 `ChatContent` 渲染独立的 `SystemMessageView` / `SystemMessageCard`。系统详情没有普通私聊气泡、输入框或私聊 More 菜单；会话列表摘要继续沿用上一节规则。
- 复用 `ChatViewModel` 的历史分页、去重、实时消息、已读、连接和账号绑定；不新增缓存、SDK 监听、接口或插件。VM 生成类型化卡片、校验动作及处理重复点击；View 只渲染与导航。
- `SystemMessageCardData` 复用 `ImCustomMessageEnvelope` 解码外层与 payload 的 Map/JSON。首版读取 `SystemComplexIMMsg.titleMap/textMap/picUrl/linkUrl/event`，支持纯文字、纯图片和图文；SDK 原生文本同样可读。正文保留换行和段落，优先当前语言、回退英文。
- 通用图文之外的系统消息显示本地化安全提示，不展示 JSON 或 `desc`；即使有 `event=2`，也只展示通用图文，不解析或执行 `eventPayload`。奖励网格、领取、支付、VIP、私密照片及活动专用按钮不在本次范围。
- 优先使用自定义消息外层有效 `timestamp`（秒或毫秒），缺失或越界回退 SDK 秒时间；两者均无效时不展示时间，不使用当前时间代替。

### Nady 布局与图片

- 对照 `/Users/huili/nady/lib/pages/main/sub_pages/message/widget/nady_system_message_widget.dart` 的通用复杂消息布局：背景 `#1C120C`、白色 10% 卡片，外边距 16、卡片内横向 16 / 纵向 24、圆角 16；图片比例 311:120，圆角 12；标题 16 半粗，正文 12，居中时间分隔。保留项目字体，不增加 Poppins。
- 视觉参数集中在 `lib/theme/`。整页与半屏共用卡片；半屏保持原约六成高度、两层返回、透明外部遮罩及房间音频规则。正文可滚动，不限制为摘要的一行。
- 图片复用 `AppNetworkImage` / 现有缓存，卡片用 cover，根导航全屏预览用 contain 和 `InteractiveViewer` 缩放。图片点击独立消费事件，不触发 Details；返回保留列表滚动位置。
- 图片不携带登录请求头；失败显示既有红色缺省图片和“重试”。重试重建图片请求，沿用缓存组件失败后的逐出机制，不改变服务端 URL。未新增 Flutter `Icon/Icons.*` 或图片资源。

### Details 与生命周期

- 仅支持有效 HTTP(S) 链接，以及已核对的 Nady `me-wallet`、`voice-room?roomId=<正整数>`；不支持的链接不展示 Details，不执行未知协议或活动参数。
- HTTP(S) 复用 `WebViewPage`，通过 `Uri` 合并 `language`，保留其他查询参数（包括重复参数）及 fragment。钱包复用 `WalletPage`；房间目标复用 `enterSharedRoom`，继续执行切房确认和密码流程，不直接替换当前房间。
- `enterSharedRoom` 增加可选动作有效性检查，在详情请求、切房确认、密码输入后重新检查。服务端错误优先显示 `msg`；无服务端文案时显示本地化兜底。
- VM 的动作代次与账号、房间生命周期隔离；预览遮住详情期间不因可见性变化误取消当前操作，但不能从被遮住的列表发起新动作。关闭、退房、被踢、切房或切账号后，迟到动作不继续导航。
- View 只移除自己持有的预览／网页／钱包路由，不盲目 `pop` 顶层页面；关闭这些页面不停止房间语音、音乐或触发 Keep/Exit。

### 验证记录

- 新增解析、动作、界面和进房保护测试，覆盖图文组合、多语言及段落、双层 JSON、异常字段、安全提示、时间单位与越界、链接白名单和编码、重复点击、分页实时更新、图片失败重试、预览返回与滚动位置。
- 覆盖整页／半屏的 320/375/430 宽度、长正文、键盘及底部安全区；覆盖退房、房间代次和账号变化清理预览，以及保留不属于本功能的顶层路由。网页、钱包和进房测试使用替身或测试路由，不执行真实支付或切房。
- 先在 `/tmp/isnow-system-message-candidates/` 生成并逐一检查候选图，再建立六张独立基线 `test/goldens/system_message_detail_{full,half}_{320,375,430}.png`。图片使用已有资源作脱敏解码样例，不代表线上通知素材；原有摘要、私聊、More、Share、音乐和礼物基线保持不变。
- 消息相关测试共 184 项、完整房间回归 559 项通过；`flutter analyze --no-pub` 和 `git diff --check HEAD` 通过。
- PLL110 真机补充：用户提供的 `127.0.0.1:9100` 是 DevTools 前端；IDE 旧调试会话已断开。App 在后台时 VM 端口无响应，用户将 App 切到前台后，通过只读调试信息找回当前 VM 地址，重新附加成功。整个过程保持 PID 5087，未重装或重启。
- 首次附加后的普通 `r` 显示 0 个库更新；检查运行中 isolate 确认新模块尚未加载，因此刷新本次 Dart 文件的修改时间，再次热重载成功更新 19 个库，并确认六个系统消息相关库已加载。文件正文没有为触发重载而改动。
- 初次查看时 IM 提示 `IM logged in on another device`，另有设备端调试高亮遮罩；用户关闭高亮并通过现有 Retry 恢复连接后，继续完成以下真机验收。Mac 独立镜像窗口的点击落点异常，后续使用 Android 设备调试接口截图、点击和滑动，不修改 App 业务数据。

### PLL110 真实图文验收结果（2026-11-03）

- 保留用户当前已进入的房间 `xtctcttf`（展示 ID `75245990`），从房间消息按钮打开列表，再进入 System 半屏。真实 SDK 历史中的图片、标题 `11` / 正文 `12`，以及较早的图片、标题 `1` / 正文 `11` 均正常展示；没有普通气泡 `[Custom message]`、私聊输入框或 More 菜单。
- 半屏历史可滑动，图片点击打开黑底根导航预览，完整等比展示。带 Details 的图文卡片点击图片也只进入预览，未触发业务链接。预览返回后仍在原历史位置；等待动画和滚动结束后，对比消息区域 `(0,1120)–(1080,2300)`，前后像素完全一致。
- 返回顺序为图片预览 → System 半屏 → Messages 列表 → 原房间。消息列表摘要仍显示真实标题 `11`，没有发送或删除动作；房间期间继续收到其他用户的公屏事件。
- 使用 Keep 保留房间，再从主消息页打开系统整页。整页复用同一图片、标题、正文、时间和 Details 布局，图片预览正常；排除悬浮入口的动画区域后，对比整页消息区域 `(0,290)–(780,2250)`，预览返回前后像素完全一致。
- 整页返回主消息页后，通过房间悬浮入口恢复同一房间。验收结束的只读状态：服务端房间 ID `2112760181039828993`，`isInRoom=true`、`isMinimized=false`、会话代次 `1`，Socket `ready`，App PID 仍为 `5087`。未重启、重装、退出房间或进入其他房间；未发送、删除、支付或打开 Details 链接。
- 音频边界：结束时 Agora 状态为 `initialized=false`、`joined=false`，因此本次不宣称真机语音收听或双机音频连续性已验收。手势缩放、真实链接跳转、异常图片重试及账号/房间切换隔离继续以自动化覆盖，本次未在真机触发这些场景。
- 本地验收截图（不作为截图基线）：`/tmp/isnow-system-device-half-return.png`、`/tmp/isnow-system-device-history-preview.png`、`/tmp/isnow-system-device-scroll-before.png`、`/tmp/isnow-system-device-scroll-after.png`、`/tmp/isnow-system-device-full.png`、`/tmp/isnow-system-device-full-preview.png`、`/tmp/isnow-system-device-full-return.png`、`/tmp/isnow-system-device-room-restored.png`。自动化基线保持不变。
