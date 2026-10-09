# iSnow 语音房完整送礼流程与动效实现说明

> 版本：v1.0 初版
>
> 状态：待业务与技术确认
>
> 面向对象：iSnow Flutter 开发人员
>
> 参考实现：`nady` 语音房送礼链路

## 0. 文档目的

本文档用于指导 `iSnow` 复刻 `nady` 的完整语音房送礼体验。文档覆盖送礼、收礼视觉反馈、连送、金币校验、背包礼物、房间公屏、礼物卡槽、礼物流水、幸运礼物、横幅、全屏礼物动画，以及麦位之间的礼物轨迹动画。

后端送礼接口、长连接事件名称和核心数据结构继续兼容 `nady`。除礼物轨迹动画外，其他效果优先复用现有 Flutter 动画能力和 `nady` 的资源格式。礼物轨迹不使用第三方动画库，由 `iSnow` 基于 Flutter 原生动画实现。

## 1. 项目信息与版本记录

| 项目 | 内容 |
| --- | --- |
| 目标项目 | `iSnow` |
| 参考项目 | `nady` |
| 功能范围 | 语音房送礼及收礼视觉反馈 |
| 客户端框架 | Flutter |
| 后端契约 | 沿用 `nady` 送礼接口、长连接事件名和数据字段 |
| 动效资源 | 支持本地资源文件；可复用 `nady` 的动画资源 |
| 第三方库限制 | 礼物轨迹不得使用第三方库 |

### 1.1 版本记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| v1.0 | 2026-10-05 | 建立送礼流程、事件契约、队列和动效实现初稿 |

## 2. 需求背景与目标

### 2.1 背景与痛点

`iSnow` 已经具备礼物目录、礼物面板、目标选择、发送接口和基础测试，但完整的收礼视觉链路尚未按 `nady` 的行为闭环接入。若只完成 HTTP 送礼请求，用户仍会遇到以下问题：

- 送礼成功后缺少即时、连续的房间反馈。
- 多人同时送礼时，礼物卡槽和 combo 队列容易无限堆积。
- 自己送礼的主态反馈可能被其他用户的客态礼物覆盖。
- 普通礼物、幸运礼物、横幅和全屏动画缺少统一的事件分发入口。
- 礼物从一个麦位飞向另一个麦位的空间反馈尚未实现。

### 2.2 业务目标

| 目标类型 | 描述 | 衡量指标 | 目标值 |
| --- | --- | --- | --- |
| 功能完整性 | 覆盖 `nady` 语音房完整送礼体验 | 核心流程通过率 | 100% |
| 兼容性 | 保持送礼接口、长连接事件和字段兼容 | 事件解析成功率 | 100% |
| 视觉反馈 | 送礼后正确展示公屏、卡槽、轨迹、横幅和全屏动画 | 事件到 UI 分发丢失率 | 0% |
| 并发体验 | 支持多人和同一用户连续送礼 | 队列无限增长 | 不允许 |
| 主态反馈 | 自己送礼时主态卡槽不被客态覆盖 | 主态被覆盖次数 | 0 |
| 轨迹动效 | 仅在起点和终点麦位均可定位时播放 | 错位或飞向空位次数 | 0 |
| 可测试性 | 核心状态和队列具备自动化测试 | 核心逻辑测试覆盖 | 必须覆盖 |

## 3. 用户与使用场景

### 3.1 用户角色

| 角色 | 说明 |
| --- | --- |
| 送礼用户 | 在语音房内选择普通礼物或背包礼物并发送 |
| 收礼用户 | 接收礼物，并在对应麦位看到礼物轨迹或其他视觉反馈 |
| 房主/麦上用户 | 作为礼物目标，提供可定位的麦位坐标 |
| 房间观众 | 接收房间公屏、礼物卡槽、横幅和全屏动画 |
| 客户端 | 发送 HTTP 请求、监听长连接、维护队列和渲染动效 |
| 服务端 | 校验余额、扣除金币、广播送礼事件和结算数据 |

### 3.2 用户旅程

| 阶段 | 用户触点 | 用户行为 | 痛点/情绪 | 产品机会点 |
| --- | --- | --- | --- | --- |
| 进入语音房 | 房间底部礼物按钮 | 点击打开礼物面板 | 不知道可送给谁 | 明确展示目标用户和麦位 |
| 加载面板 | 礼物分类、金币余额、背包 | 浏览礼物并切换分类 | 网络慢或列表为空 | 加载态、失败重试、空态 |
| 选择目标 | 目标栏和用户列表 | 选择单人、多用户、全麦位或全房间 | 目标范围容易误解 | 明确展示目标数量和预计消耗 |
| 选择礼物 | 礼物网格 | 选择普通礼物或背包礼物 | 不知道库存和金币是否足够 | 展示价格、库存、连送配置 |
| 设置数量 | 数量选择器/连送入口 | 选择数量并点击发送 | 多目标总价计算复杂 | 实时展示总数量和总消耗 |
| 发送请求 | 发送按钮 | 提交送礼请求 | 重复点击、余额不足、网络失败 | 防重复提交、错误提示、恢复状态 |
| 服务端广播 | 房间长连接 | 等待房间反馈 | 成功但反馈延迟 | 统一事件分发和状态去重 |
| 收礼反馈 | 公屏、卡槽、轨迹 | 观看礼物效果 | 多人同时送礼容易被覆盖 | 主态/客态卡槽和队列策略 |
| 连送阶段 | combo 卡槽、数量动画 | 连续点击或等待 combo | 队列越积越长 | 按 comboId 合并并覆盖旧数据 |
| 动效结束 | 全屏动效、横幅、轨迹 | 继续房间互动 | 动效阻塞其他事件 | 分层播放、独立生命周期 |

## 4. 需求功能清单

| 优先级 | 功能模块 | 主要能力 | 状态 |
| --- | --- | --- | --- |
| P0 | 礼物目录 | 普通礼物、分类、背包礼物、资源字段解析 | `iSnow` 已有基础，需要补齐兼容字段 |
| P0 | 目标选择 | 指定单人、多目标、全部麦位、全房间、是否允许给自己 | `iSnow` 已有基础，需要与 nady 行为完全对齐 |
| P0 | 送礼请求 | 金币/库存校验、请求防抖、接口成功/失败状态 | `iSnow` 已有基础，需要补齐闭环 |
| P0 | 长连接分发 | 统一接收和解析礼物相关事件 | 待实现 |
| P0 | 收礼公屏 | 展示送礼人、礼物、数量、目标等信息 | 待接入 |
| P0 | 礼物卡槽 | 主态/客态、combo 合并、过期清理、并发覆盖 | 待实现 |
| P0 | 礼物轨迹 | 从送礼麦位飞向可定位的目标麦位 | `iSnow` 自研 |
| P0 | 全屏大动画 | 本地资源或服务端资源驱动，播放结束后释放队列 | 待接入 |
| P0 | 礼物横幅 | 普通和幸运礼物横幅 | 待接入 |
| P0 | 幸运礼物 | 幸运礼物气泡、倍率、中奖金币反馈 | 待接入 |
| P0 | 礼物流水 | 房间周流水等数据更新 | 待接入 |
| P1 | 动效资源缓存 | 礼物图片、动画资源本地缓存 | 待接入 |
| P1 | 诊断日志 | 记录事件解析、队列、动效失败 | 待接入 |

## 5. 现有代码与目标架构映射

### 5.1 `iSnow` 已有模块

| 责任 | 当前模块 |
| --- | --- |
| Socket 消息源 | `lib/manager/app_socket_manager.dart` |
| 房间 Socket 消息模型 | `lib/model/room_socket_message.dart` |
| 房间仓库 | `lib/classes/room/room_repository.dart` |
| 礼物目录 API | `lib/classes/room/gift/room_gift_repository.dart` |
| 礼物目录缓存 | `lib/manager/room_gift_manager.dart` |
| 礼物模型与送礼请求 | `lib/classes/room/gift/models/room_gift_models.dart` |
| 礼物状态 | `lib/classes/room/gift/viewmodel/room_gift_state.dart` |
| 礼物交互 ViewModel | `lib/classes/room/gift/viewmodel/room_gift_view_model.dart` |
| 礼物面板 | `lib/classes/room/gift/views/room_gift_sheet.dart` |
| 礼物入口 | `lib/classes/room/views/room_bottom_bar.dart` |

### 5.2 建议新增的客户端边界

新增一个房间级 `RoomGiftEventManager` 或等价的 Riverpod provider，职责只包括：

1. 订阅 `RoomRepository.socketMessages`。
2. 按事件名解析 `RoomScreenGiftMsg` 及相关礼物事件。
3. 将同一个事件转换为多个只读渲染状态：公屏、卡槽、轨迹、横幅、全屏动画、幸运礼物和流水。
4. 统一处理房间切换、离开房间、Socket 重连和资源释放。
5. 保持 UI 组件不直接依赖原始 Socket payload。

建议的数据流：

```text
AppSocketManager.messages
        |
        v
RoomRepository.socketMessages
        |
        v
RoomGiftEventManager
        |
        +--> GiftPublicScreenState
        +--> GiftSlotState
        +--> GiftTrajectoryTask
        +--> GiftBannerTask
        +--> GiftFullScreenTask
        +--> LuckyGiftState
        +--> GiftStreamState
```

## 6. 礼物目录与面板流程

### 6.1 目录加载

打开礼物面板时，使用 `RoomGiftRepository` 获取并缓存以下数据：

| 数据 | 接口 | 用途 |
| --- | --- | --- |
| 普通礼物分类 | `/api/gift/info/tabGiftList` | 礼物分类和礼物列表 |
| 背包礼物 | `/api/gift/info/getBackpack` | 背包分类和库存 |
| 金币余额 | `/api/revenue/purse` | 金币校验和余额展示 |
| 是否允许给自己送礼 | `/api/system/config/sendByOneself` | 目标列表过滤 |

目录缓存必须按登录用户隔离，并合并并发加载请求，避免应用预加载和打开礼物面板同时重复请求。空目录不得写入长期缓存，下一次打开时允许重试。

### 6.2 礼物模型字段

普通礼物和背包礼物至少保留以下字段：

| 字段 | 说明 |
| --- | --- |
| `id` | 礼物 ID |
| `name` | 礼物名称 |
| `icon` | 礼物图标 |
| `price` | 单个礼物金币价格 |
| `isCombo` | 是否支持连送 |
| `tabId` | 所属分类 |
| `amount` | 背包库存数量 |
| `userBackpackId` | 背包礼物实例 ID |
| `defaultGiftNum` | 默认赠送数量 |
| `defaultGiftNumConfig` | 可选赠送数量配置 |
| `animationUrl` | 动画资源地址或资源标识 |
| `animationType` | 动画资源类型 |
| `giftType` | 礼物业务类型 |
| `itemType` | 礼物/道具类型 |
| `direction` | 方向或动效方向配置 |

数量配置为空时，沿用 `nady` 默认值 `[1, 8, 18, 888]`，但发送前仍必须根据实际金币和库存校验。

## 7. 送礼流程

### 7.1 目标模式

必须完整保留 `nady` 的目标模式和对应发送类型：

| `RoomGiftTargetMode` | `sendType` | 含义 | `targetUids` |
| --- | ---: | --- | --- |
| `selected`，单人 | `1` | 指定一名用户 | 单个 UID |
| `allMic` | `2` | 当前所有麦位用户 | 所有可用麦位 UID |
| `allRoom` | `3` | 全房间用户 | `null` 或空列表，按后端契约 |
| `room` | `4` | 保留兼容类型 | 按后端原有语义 |
| `selected`，多人 | `6` | 指定多名用户 | 多个 UID |

目标选择规则：

- 允许给自己送礼时，自己的 UID 可以出现在目标列表中。
- 不允许给自己送礼时，从可选目标中移除当前用户。
- `allMic` 的目标数量等于当前可用麦位目标数量。
- `allRoom` 的目标数量使用在线人数展示，但实际请求不伪造全部 UID。
- 送礼轨迹只使用当前能映射到麦位坐标的目标；不能定位的目标仍参与服务端送礼和公屏/卡槽反馈。

### 7.2 请求字段

`iSnow` 继续使用当前 `SendRoomGiftRequest` 字段：

```json
{
  "targetUids": [1001, 1002],
  "sendType": 6,
  "roomId": "20001",
  "giftId": 31,
  "giftCount": 8,
  "giftSource": 1,
  "comboId": "",
  "comboCount": 1,
  "price": 20,
  "userBackpackId": null
}
```

字段规则：

- 普通礼物：`giftSource = 1`。
- 背包礼物：`giftSource = 2`，必须携带 `userBackpackId`。
- `giftCount` 是每个目标的赠送数量。
- 多目标总数量为 `giftCount * targetCount`。
- 金币总消耗为 `price * giftCount * targetCount`。
- combo 初始请求使用空 `comboId` 和 `comboCount = 1`；后续使用 HTTP 成功返回的 `comboId`。请求的 `comboCount` 是本次点击次数，单次点击为 1；广播累计次数只用于展示，不回填到请求数量。

### 7.3 发送前校验

发送按钮点击后必须按以下顺序校验：

1. 当前没有正在发送请求。
2. 已选择礼物。
3. 非全房间模式下至少存在一个目标。
4. 背包礼物库存不小于总发送数量。
5. 普通礼物金币余额不小于总消耗。
6. 请求提交期间禁用重复发送。

### 7.4 请求结果

- HTTP 成功：更新本地金币或背包库存，关闭发送中状态。
- HTTP 失败：不扣除本地余额，不播放收礼动效，显示服务端错误并恢复发送按钮。
- HTTP 成功但长连接事件尚未到达：支持连送的礼物立即显示 Combo 入口（使用 HTTP 返回的 comboId）；公屏、卡槽、轨迹、横幅和全屏动画仍以服务端长连接事件为准，不伪造广播。
- 重新发送不由客户端自动重试，避免重复扣费。是否允许用户手动再次点击由服务端错误类型决定。

## 8. 长连接事件契约

`iSnow` 使用已有 `RoomSocketMessage` 接收消息，并在 `RoomGiftEventManager` 内按 `event` 分发。事件名称必须保持大小写和拼写一致。

| 事件 | 用途 | 主要消费者 |
| --- | --- | --- |
| `roomScreenSendGiftComboEvent` | 房间送礼 combo 事件 | 公屏、卡槽、轨迹、普通礼物效果 |
| `RoomSendGiftPublicScreenEvent` | combo 结束后的送礼公屏 | 公屏 |
| `RoomGiftStreamUpdateEvent` | 房间礼物流水更新 | 流水/榜单状态 |
| `RoomGiftSendBannerEvent` | 普通送礼横幅 | 横幅 |
| `RoomLuckGiftSendBannerEvent` | 幸运礼物横幅 | 横幅、幸运礼物 |
| `LuckyGiftSendMsg` | 幸运礼物结果或状态 | 幸运礼物气泡、中奖反馈 |
| `LuckyGiftSmallMultiple` | 幸运礼物小倍率 | 幸运效果 |
| `LuckyGiftBigMultiple` | 幸运礼物大倍率 | 幸运效果 |
| `LuckyGiftJackpotSuperMode` | 幸运礼物 Jackpot 模式 | Jackpot 效果 |

### 8.1 `RoomScreenGiftMsg` 字段

`roomScreenSendGiftComboEvent` 的 payload 按 `nady` 的 `RoomScreenGiftMsg` 解析：

| 字段 | 类型 | 用途 |
| --- | --- | --- |
| `gift` | `RoomMsgGiftModel` | 礼物信息和动画字段 |
| `count` | `int` | 当前事件数量 |
| `giftCount` | `int` | 本次礼物数量 |
| `comboCount` | `int` | 当前连送次数 |
| `giftSource` | `int` | 普通礼物/背包礼物 |
| `sendType` | 枚举/整数 | 送礼目标模式 |
| `gold` | `int` | 相关金币值 |
| `uids` | `List<int>` | 目标 UID 列表 |
| `event` | `String` | 事件名 |
| `uid` | `int` | 送礼用户 UID |
| `userInfo` | `BaseUserInfo` | 送礼用户信息 |
| `targetUsers` | `BaseUserInfo?` | 目标用户信息，可能为空 |
| `isHideLuckyGift` | `bool` | 是否隐藏幸运礼物效果 |
| `isLuckyGift` | `bool` | 是否为幸运礼物 |
| `playWinGoldCount` | `bool` | 是否播放中奖金币数量 |
| `totalCoinCount` | `int` | 累计金币数量 |
| `totalGiftCount` | `int` | 累计礼物数量 |
| `comboId` | `String` | 同一连送链路 ID |
| `roomId` | `String` | 房间 ID |
| `isJackpot` | `bool` | 是否 Jackpot |

解析失败、字段缺失或房间 ID 不匹配时，必须记录日志并丢弃当前视觉事件，不得影响 Socket 主连接和其他房间事件。

## 9. 收礼视觉反馈

同一份服务端礼物事件进入统一分发器后，按以下方式生成独立的渲染任务。

### 9.1 房间公屏

- 展示送礼人、礼物图标、礼物名称、数量和目标信息。
- 普通 combo 事件可更新当前公屏内容，不要求每个 combo 都创建一条永久消息。
- `RoomSendGiftPublicScreenEvent` 用于 combo 结束后的最终公屏结果。
- 公屏展示失败不得影响卡槽、轨迹或全屏动画。

### 9.2 礼物卡槽

- 普通状态下展示队列中最新的两条礼物。
- 当队列中出现自己的送礼数据时，绑定一个主态卡槽；另一个卡槽作为客态卡槽。
- 主态卡槽只展示自己的礼物，不能被客态数据覆盖。
- 客态卡槽可以继续按最新客态数据更新。
- 当前队列不存在主态数据时，解除绑定并恢复最新两条展示策略。
- 主态和客态均无数据时保持空态，不显示占位礼物。

### 9.3 礼物轨迹

礼物轨迹是 `iSnow` 自研的新增动效，不使用第三方轨迹动画库。

轨迹任务至少包含：

```text
eventKey
giftId
giftIcon / localAsset
senderUid
targetUid
sourceSeatPosition
targetSeatPosition
sourceOffset
targetOffset
giftCount
createdAt
```

播放规则：

1. 从送礼事件中获得送礼人 UID 和目标 UID 列表。
2. 从当前房间麦位坐标注册表获取起点和终点坐标；发送人不在麦位上时使用底部礼物按钮的注册坐标作为备用起点。
3. 只有起点和终点都能定位时，才创建轨迹任务。
4. 多个可定位目标分别创建独立轨迹任务。
5. 目标无法定位、麦位已经离开或房间已切换时，跳过轨迹任务。
6. 跳过轨迹不影响公屏、卡槽、横幅和全屏动效。

推荐实现方式：

- 在房间页面维护麦位 UID 到 `Rect/Offset` 的注册表。
- 轨迹层使用 Flutter `Stack` 或 `Overlay` 作为渲染容器。
- 每个轨迹任务使用 `AnimationController` 驱动 `Tween<Offset>`。
- 直线或曲线路径使用 Flutter 原生 `Tween`、`Curve`、`PathMetric` 或 `CustomPainter` 实现。
- 轨迹图标从本地资源文件或礼物缓存中读取。
- 任务完成、取消、房间离开和 Widget dispose 时必须释放 controller。
- 轨迹层只负责动画，不直接请求接口、不修改金币、不解析原始 Socket payload。

### 9.4 横幅

- `RoomGiftSendBannerEvent` 展示普通送礼横幅。
- `RoomLuckGiftSendBannerEvent` 展示幸运礼物横幅。
- 横幅使用独立队列或定时器，不阻塞全屏礼物队列。
- 同一个 combo 可按 `comboId` 合并更新，避免横幅无限堆积。

### 9.5 全屏大动画

全屏动画按照礼物字段解析资源类型，可以复用 `nady` 当前的资源文件和 Flutter 播放方式：

- SVGA：使用现有 SVGA 播放封装或等价的项目能力。
- MP4/VAP：按 `animationType` 和 `videoMode` 选择播放器。
- PAG：使用现有 PAG 播放能力。
- 普通 Flutter 动画：使用 `AnimationController`、`AnimatedBuilder` 等原生组件。

播放完成必须回调队列移除逻辑。资源缺失或播放失败时，移除当前任务并继续后续任务，不得卡住全屏队列。

### 9.6 幸运礼物

- 根据 `isLuckyGift`、`isHideLuckyGift`、`isJackpot` 等字段选择幸运效果。
- combo 更新时，使用累计数量计算本次新增数量，避免重复播放历史数量。
- `playWinGoldCount` 为真时，展示中奖金币数量动画。
- 幸运礼物气泡和普通礼物卡槽可以同时存在，但不得重复消费同一事件。
- 进入后台或离开房间时停止视觉播放，回到房间后不补播已过期的旧动画。

## 10. 队列与并发规则

### 10.1 combo 合并

- 使用 `newComboId` 或 `comboId` 识别同一连送链路。
- 同一 combo 的新事件替换旧展示数据，并保留队列位置和最新累计数量。
- 新的 combo 直接进入最新位置，保证其他用户的新送礼可以及时露出。
- 幸运礼物在隐藏效果标记开启时，不重复创建旧的幸运结果动画。

### 10.2 过期清理

- 礼物卡槽任务创建时间超过约 5 秒后清理。
- 使用周期任务定期清理过期任务，参考 `nady` 的 2 秒清理周期。
- 清理任务不能删除仍在播放的全屏动画实例，动画实例由自身完成回调移除。
- 房间离开、房间切换和 Socket 重置时清空所有礼物队列。

### 10.3 主态和客态

主态指当前登录用户发送的礼物，客态指其他用户发送的礼物。

- 有主态数据时，主态卡槽持续存在，客态不能挤掉主态。
- 主态连续送礼时，只更新主态卡槽的 combo 和累计数量。
- 客态高频送礼时，只更新客态卡槽或客态队列。
- 主态数据全部过期后解除主态槽位绑定。
- 不固定上方或下方卡槽为主态槽位，首次获得主态数据的槽位保持绑定。

## 11. 动效资源管理

礼物图片、礼物图标和动画文件可以直接存储为项目资源文件。建议新增统一资源解析层，例如 `GiftAssetResolver`：

- 先检查本地资源映射。
- 本地不存在时再使用服务端 `animationUrl` 或 `icon`。
- 资源下载和缓存失败时使用礼物静态图标或跳过对应动效。
- 礼物资源缓存与普通图片缓存分离。
- 页面销毁时不持有动画 controller、文件句柄和临时缓存对象。

资源类型判断应集中在一个地方，不应由卡槽、公屏、轨迹和全屏动效各自解析 `animationType`。

## 12. 异常与边界处理

| 场景 | 处理要求 |
| --- | --- |
| 礼物目录加载失败 | 面板显示失败态和重试入口 |
| 礼物目录为空 | 显示空态，不写入长期缓存 |
| 金币不足 | 不提交请求，提示充值或余额不足 |
| 背包库存不足 | 不提交请求，提示库存不足 |
| 目标为空 | 禁止发送并提示选择目标 |
| 重复点击发送 | 发送期间禁用按钮 |
| HTTP 发送失败 | 不更新余额，不创建视觉动效 |
| HTTP 成功但事件延迟 | 确认 comboId 后显示 Combo，收礼反馈等待服务端事件 |
| Socket payload 解析失败 | 记录日志并丢弃当前事件 |
| 房间 ID 不匹配 | 丢弃当前视觉事件 |
| 目标不在麦位 | 不播放轨迹，保留公屏和卡槽 |
| 起点不在麦位 | 从礼物按钮的注册坐标飞出；备用起点也不存在时跳过轨迹 |
| 动画资源失效 | 跳过该动画，继续其他队列 |
| 多人高频送礼 | 按 combo、主客态和过期规则合并/覆盖 |
| App 进入后台 | 停止非必要动画，不补播过期事件 |
| 离开语音房 | 取消订阅、清空队列、释放动画资源 |
| Socket 重连 | 不重复消费历史事件，继续接收新事件 |

## 13. Flutter 测试要求

### 13.1 模型与契约测试

- `RoomGift.fromJson` 正确解析普通礼物、背包礼物、动画字段和数量配置。
- `SendRoomGiftRequest.toJson` 与 `nady` 字段名和值兼容。
- `RoomScreenGiftMsg` 能解析完整 payload 和默认字段。
- 缺少可选字段时使用默认值，不因单个字段缺失崩溃。
- `RoomSocketMessage` 能正确保留事件名、payload、时间戳和房间信息。

### 13.2 ViewModel 和 Repository 测试

- 礼物目录、背包、余额和是否允许给自己送礼能够合并加载。
- 并发打开多个礼物面板只产生一次目录请求。
- 普通礼物金币不足时不发送请求。
- 背包礼物库存不足时不发送请求。
- 单人、多目标、全麦位和全房间模式生成正确的 `sendType` 和 `targetUids`。
- 发送成功后更新本地金币或背包库存。
- 发送失败后恢复状态，不修改本地余额。
- 发送期间重复点击不会产生重复请求。

### 13.3 事件分发测试

- `roomScreenSendGiftComboEvent` 被转换为公屏、卡槽和收礼反馈任务。
- `RoomSendGiftPublicScreenEvent` 只更新 combo 结束后的公屏结果。
- `RoomGiftSendBannerEvent` 和幸运礼物横幅进入独立横幅队列。
- `RoomGiftStreamUpdateEvent` 更新流水状态。
- 未知事件不会影响其他事件处理。
- 房间 ID 不匹配的事件不会进入当前房间 UI。
- 同一个事件不会被重复消费。

### 13.4 队列测试

- 同一 `comboId` 的连续事件能够合并并更新累计数量。
- 新 combo 能立即进入最新展示位置。
- 主态卡槽不会被客态数据覆盖。
- 客态高频事件只更新客态卡槽。
- 主态过期后恢复最新两条展示策略。
- 5 秒过期任务能够被清理。
- 房间离开后所有队列清空。
- 多人同时送礼不会造成队列无限增长。

### 13.5 礼物轨迹 Widget 测试

- 起点和终点麦位均可定位时创建轨迹。
- 起点或终点无法定位时不创建轨迹。
- 多目标送礼只为可定位目标创建轨迹。
- 麦位坐标变化后，新任务使用最新坐标。
- 轨迹完成后移除任务并释放 controller。
- Widget dispose 时所有 controller 被释放。
- 轨迹失败不影响公屏和卡槽任务。

### 13.6 动效集成测试

- 普通礼物能正确播放本地资源。
- 幸运礼物能根据倍率和 Jackpot 字段选择正确效果。
- 全屏动画播放完成后继续下一个任务。
- 动画资源缺失时不会阻塞队列。
- 公屏、卡槽、轨迹、横幅和全屏动画可以并行存在。
- App 进入后台、离开房间和 Socket 重连后没有重复播放或内存泄漏。

## 14. 建议落地文件

以下为建议的 `iSnow` 实现边界，实际命名可以遵循项目现有规范：

```text
lib/classes/room/gift/
├── models/room_gift_models.dart
├── room_gift_repository.dart
├── viewmodel/room_gift_state.dart
├── viewmodel/room_gift_view_model.dart
├── event/room_gift_event_manager.dart
├── event/room_gift_event_parser.dart
├── queue/room_gift_slot_queue.dart
├── trajectory/room_gift_trajectory_layer.dart
├── trajectory/room_gift_trajectory_task.dart
├── effects/room_gift_effect_layer.dart
├── effects/room_gift_asset_resolver.dart
└── views/room_gift_sheet.dart
```

建议的 UI 分层顺序：

```text
RoomPage
├── RoomGiftFullScreenEffectLayer
├── RoomGiftTrajectoryLayer
├── RoomGiftBannerLayer
├── RoomGiftSlotLayer
├── RoomGiftPublicScreenLayer
└── RoomGiftSheet
```

各层只订阅自己的渲染状态，不直接操作 HTTP、Socket 或余额状态。

## 15. 初版确认点

本版已固化以下业务决定：

- 目标用户是 `iSnow` Flutter 开发人员。
- 只支持语音房场景。
- 完整复刻 `nady` 送礼体验。
- 普通礼物和背包礼物都必须支持。
- 所有 `nady` 送礼目标模式都必须支持。
- 收礼重点是房间内视觉反馈。
- 长连接事件名称和数据结构保持兼容。
- 队列规则按 `nady` 当前主态/客态和 combo 策略执行。
- 礼物轨迹只对可定位麦位播放。
- 礼物轨迹不使用第三方库。
- 需要覆盖模型、ViewModel、事件、队列、轨迹和动效集成测试。

待确认后进入下一步：将核心送礼流程拆成 Mermaid 交互流程，并根据确认后的规则补充实现原型/交互切片。
