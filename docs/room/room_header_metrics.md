# 房间 Header 热度与榜单入口

保留现有封面、房名、ID 和分享布局，替换两项指标。在线列表及礼物 All room 数量仍使用真实在线人数，与这里的热度无关。

| 展示项 | Nady 对应数据 | iSnow 处理 |
| --- | --- | --- |
| 热度 | `GET /api/room/getHotScore?roomId=真实房间ID`，data 为整数 | 首次显示、恢复前台／Keep 和 Socket 重连时读取；可见期间每 100 秒刷新，在线变更事件触发合并请求 |
| 贡献榜 | 房间详情 `roomGiftWeekVal` | 详情初值；`RoomGiftStreamUpdateEvent.roomWeekVal` 实时覆盖，Keep 期间也保留更新 |
| Profit Rank | 房间详情 `roomGiftIncomeVal` | 沿用 Nady 缺省 0；未加载详情时显示 `—` |

贡献榜与 Profit Rank 每 5 秒纵向切换，动画 500ms；点击进入当前展示的榜单分类，榜单默认周榜。停止可见时暂停轮播；新房间会话回到贡献榜。原来的“已占麦位／总麦位”数值从此入口移除。

轮播入口按当前图标、格式化数值和两侧内边距自适应宽度，切换分类或数值更新时重新测量，使用实际字体、语言及系统文字缩放。`RoomHeaderTheme.metricMaxWidth` 仅为 74 的设计上限，不再固定撑满；高度、轮播节奏与点击行为保持不变。宽度版本截图独立保存在 `test/goldens/room_header_adaptive_width_v3/`，保留 v2 历史图片。

自适应宽度验证：320／375／430 的短值、长值、切换后收窄和实时更新测试通过；相关 116 项测试通过，静态分析及差异检查通过。32 张新旧截图差异仅位于 Header（y < 79），历史 PNG 未改动。本轮未执行设备热重载或热重启。

热度首次加载失败显示 `—`，重试失败保留最近有效值，不冒用在线人数或伪造 0。Repository 使用 HttpApi 和 HttpDioManager，View 不请求接口。所有迟到请求受账号、房间代次、前后台及关闭检查保护。RoomManager 保存本会话贡献值；开始于较早时间的详情请求不能覆盖后来的 Socket 更新，后续新详情可重新校准。离房和重新进房清除覆盖值。

榜单汇总接口 `/api/room/rank/val` 修正为 Nady 的 `type=5/4/3`（日／周／月）和 roomId；榜单列表仍使用其原有 `frequencyType` 参数。汇总数据与 Header 详情字段分别使用，不能拿在线人数或麦位数替代。

## 资源与验证

三张用户原图及 AppAssets 映射见 `room_ui_asset_policy.md`；manifest 记录精确本地路径，pubspec 已声明整个房间资源目录。原文件和复制文件 SHA-256 一致。

- `room_header_metrics_test.dart`：接口路径、参数、0、错误 msg、合并请求、100 秒刷新、Keep、账号／会话失效、Socket 覆盖与迟到详情。
- `room_header_carousel_test.dart`：320／375／430 宽度、长房名、数值与图标配对、手动切换、5 秒轮播以及两个目标榜单。
- 新 Header 截图位于 `test/goldens/room_header_metrics_v2/`。23 张旧全房间截图差异最初均位于 Header（最高到 y=79）；More Setting 的另外 3 张亦仅 Header 不同。人工核对后使用该目录的 regression 子目录独立保存新版，历史图片不覆盖，其他组件基线不变。修改前已有的 9 项全房间截图失败源于用户已暂存的 Header 布局与历史基线不一致。
- 本次不实际送礼、不发送消息、不提交房间管理操作。

2026-11-08 验证：完整 `test/room*_test.dart` 共 660 项通过，`flutter analyze --no-pub` 无问题，`git diff --check HEAD` 通过；没有新增 Flutter Icon，历史 PNG 未修改。Pixel_9 已附加到现有 iSnow 调试进程，但有效代码热重载被 VM 以 `Const class cannot remove fields ... RoomState` 拒绝，未执行热重启。当前仍为原有 hei 房间（展示 ID 30317291），设备上的新 Header 视觉及真实接口数值尚未验收，不能把自动化截图当作模拟器验收。
