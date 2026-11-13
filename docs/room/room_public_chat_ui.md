# 房间公屏消息 UI

## 设计与边界

- 来源：蓝湖 `cc03dc0c-a1e5-4dcc-ba8f-6bb2cfd909d2`（直播间－15麦位），Schema 中 `group_28 flex-col justify-between` 为用户信息区，`group_44` 为下方正文，`text-wrapper_2` 为系统提示。
- 375 基准：头像含框 40、右间距 3；昵称 14、徽章高 16；正文 13、内边距 8。默认正文为 40% 黑底，圆角依次为 6/16/16/16；系统提示为 55% 黑底、粉色正文。
- 公屏右侧预留 75，系统提示预留 70，避免与 Rocket、Game Big Win、大厅挂件重叠。尺寸随 ScreenUtil 适配，正文宽度还受实际可用空间约束。
- 昵称单行省略；等级与昵称优先同排，放不下时换行；其他真实装饰按需换行，没有装饰时不保留空行。正文完整换行，不再限制四行，短气泡按内容收缩。
- 结构沿用 Nady：左侧为头像，右侧同一个纵向区域容纳身份区和正文，顶部对齐。正文与身份区实际底边的间距为 6，不等待 40 高头像结束；只有昵称时不会留下约 30 的空白，多行徽章仍按实际高度下推正文。正文不再单独增加头像宽度的缩进。
- 普通文本、入场、图片、表情、Party 和礼物复用 `RoomPublicMessageFrame`。系统提示无用户头像。头像/昵称打开既有用户卡，`@`、图片预览、Party 导航和礼物中奖内容继续使用既有回调。
- 本次统一蓝湖默认气泡，不读取用户佩戴的个性气泡，不迁移额外业务消息动作。

## 数据与分层

- `RoomChatEntry.senderAppearance` 和 `RoomGiftUser.appearance` 为可选字段，默认空装饰，兼容旧构造；不改 HTTP 接口或 Socket 协议。
- 复用 `RoomUserAppearance` 解析发送者：普通消息使用 `from` 等既有字段，礼物使用已有 `from` / `userInfo`。解析在 Model / ViewModel 中完成；View 不读取 JSON，不逐条请求用户资料。
- `avatarWidget.animationUrl/icon` 由既有动画与图片缓存能力显示。昵称、头像、性别、国家、等级均使用真实字段。
- 等级使用 `userLevel` 的 wealth/charm/active 数值和对应图标；非正等级隐藏。贵族、VIP、铭牌、标签、佩戴勋章及认证使用服务端资源，VIP 优先 `vipMedal`，旧数据兼容 `vipIcon`。勋章按 `sortingOrder` 排序。
- 贵族与铭牌图片按当前语言取值，缺失回退英文，再使用通用图片。没有真实所有权的数据不生成示例徽章；已拥有但没有可用资源时显示红色缺省图。
- 保留 Socket 单一回显、有效消息 ID 去重、80 条列表上限、清屏、分类及房间代次隔离。消息 ID 用作 UI 身份，避免列表移位复用其他消息的内部状态。

## 资源

- 下载脚本按该设计稿和原始图层 `I15344:276765;15186:295461` 精确提取通用男性符号 `room_chat_gender_male.png`。女性符号复用项目已有蓝湖资源，国旗复用现有 country_flags。
- 脚本同时保留 HTML `img` / CSS 背景解析能力；不下载该稿示例人物、头像框或写死等级数字的图层作为用户数据。现有同 URL 的通用图标不重复导出。
- AppAssets、资源 manifest 和 `assets/lanhu/room/` 声明配套维护。所有视觉值位于 `RoomPublicChatTheme`；禁止使用 Flutter Icon / Icons.*。

## 验收记录

2026-11-13 验收：

| 检查 | 结果 |
| --- | --- |
| 公屏新增 Model / Widget / 手势测试 | 16 项通过：装饰、语言回退、异常字段、不同消息类型、真实目标回调、昵称省略、徽章换行、长正文、RTL、键盘和消息更新中的 @ 点击 |
| 完整房间回归 `flutter test --no-pub --concurrency=4 --reporter=expanded test/room*_test.dart` | 712 项通过，包含 Socket 单一回显、清屏、私聊、Share、音乐、送礼、Keep/Exit 与房间生命周期 |
| 资源脚本 `python3 -m unittest tools.tests.test_download_lanhu_room_assets` | 8 项通过，包含精确原始图层提取与排除示例用户图层 |
| `flutter analyze --no-pub` / `git diff --check HEAD` | 通过 |

- 先在 `build/qa/room_public_chat/` 生成并核对 320/375/430 的候选图，再建立 `test/goldens/room_public_chat_lanhu_v1/` 三张独立公屏基线。
- 完整房间回归涉及 14 张整页截图；逐项对照并核对像素差异范围，变化仅在公屏通知和送礼消息区域。为这些场景新增 `regression/` 基线并显式迁移断言，旧版所有截图文件均保留且无修改；没有覆盖 Share、音乐或 More 的独立基线。
- 截图使用测试用户资料和现有图片 fixture；运行时只展示消息中的真实数据。截图不作为真实账号资料或后端联调证据。
- Pixel_9 已连接，但前台为 Miloop，iSnow 无运行进程和可用 Flutter 调试会话。没有为本次验收启动、安装或重启 App，没有重新进房；本轮**未完成设备热重载验收**，字体实际回退和原生装饰动画仍需在 iSnow 调试会话中查看。
- 全部消息发送、送礼及管理流程仅使用替身；没有实际发送消息、送礼或提交管理操作。

## 紧凑布局修正（2026-11-13）

- 原来的“头像和身份区一行、正文另起一行”使无徽章消息也必须等待头像底部，昵称下方因此多出约 24 的空白。现改为 Nady 的左右结构：头像顶部对齐右侧列，右侧列依次为实际身份区、6 间距和正文；不做负位移或重复头像缩进。
- 新增 18 项间距测试，覆盖 320/375/430、LTR/RTL、无徽章、单行等级及多行徽章；检查真实间距、头像/身份顶部对齐、正文左右对齐、宽度限制及多行内容不重叠。公屏布局与交互合计 29 项通过，礼物端到端替身场景 12 项通过。
- 人工核对候选图后新增 `test/goldens/room_public_chat_compact_v2/` 的三张概览及四张礼物场景截图。测试仅将这些场景切换至 v2；v1 和其他历史图片保留，原有 217 张基线通过 SHA-256 一致性检查。
- 字体、头像、气泡、装饰数据、右侧挂件避让、系统提示、接口和消息去重不变；本轮没有进行设备或真实账户操作。
- 最终完整回归使用 `flutter test --no-pub --concurrency=1 --reporter=expanded test/room*_test.dart`，730 项全部通过；`flutter analyze --no-pub` 和 `git diff --check HEAD` 通过。首轮并行测试加载停滞后仅重新启动本次测试，没有清理源码、安装包或其他项目。
