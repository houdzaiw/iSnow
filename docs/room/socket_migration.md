# nady 房间 Socket 迁移清单

静态分析时间：2026-08-21  
来源项目：`/Users/liqihui/nady`  
目标项目：`/Users/liqihui/iSnow`  
范围：`lib/services/long_link`、房间内动态订阅方、socket 相关 model。

## 当前实现摘要

nady 使用 `centrifuge` 作为长连接客户端。`LongLinkManager` 初始化全局连接，进入房间时追加房间频道订阅。

| 类文件名 | 关键方法 | 职责 |
| --- | --- | --- |
| `long_link_manager.dart` | `build()` | 获取长连接 URL，创建 `centrifuge.Client`，连接并订阅全局频道 |
| `long_link_manager.dart` | `joinRoom(roomID)` | 订阅 `room:{roomID}` 和 `room`，启动心跳 |
| `long_link_manager.dart` | `leaveRoom(roomID)` | 关闭房间频道监听并停止心跳 |
| `nady_long_link_handler.dart` | `subscribe(channel, client, requestToken)` | 创建频道订阅，解析 publication，按 event 分发 |
| `nady_long_link_handler.dart` | `addSubscriber/removeSubscriber` | 维护 event -> handlers |
| `long_link_room_id_handler.dart` | `subscribe(client, roomId)` | 当前房间事件处理核心 |
| `long_link_room_handler.dart` | `subscribe(client)` | 全房横幅频道 |
| `long_link_global_handler.dart` | `subscribe(client)` | 全局事件 |
| `long_link_global_user_handler.dart` | `subscribe(client)` | 用户定向全局事件 |
| `long_link_game_handler.dart` | `subscribe(client)` | 游戏频道 |
| `long_link_game_user_handler.dart` | `subscribe(client)` | 用户游戏频道 |
| `long_link_global_lobby_handler.dart` | `subscribe(client)` | 游戏广场/大厅事件 |

## 连接与鉴权参数

| 字段名 | Dart 类型 | 含义 | 来源 | 是否必填 | 使用位置 |
| --- | --- | --- | --- | --- | --- |
| `url` | `String` | Centrifugo 连接地址 | `GET /config/long-link-url`，`ConfigApi.of.getLongLinkUrl()` | 是 | `LongLinkManager.build` -> `centrifuge.createClient(url, ...)` |
| `connectionToken` | `String` | socket 连接 token | `GET /token/long-link`，`TokenApi.of.getLongLinkToken()` | 是 | `ClientConfig.getToken` |
| `channel` | `String` | 订阅频道名 | 代码拼接：`global`、`global:{uid}`、`room:{roomId}` 等 | 是 | `LongLinkHandler.subscribe` |
| `subscriptionToken` | `String` | 频道订阅 token | `GET /api/room/genGlobalToken?channel={channel}` | 是 | `SubscriptionConfig.getToken` |
| `uid` | `int?` | 当前登录用户 ID | `authenticationUIDProvider.value` | 是 | 用户频道、心跳 |
| `roomId` | `String` | 当前房间 ID | `RoomManager.currentRoomID` | 房间频道必填 | `joinRoom/leaveRoom` |
| `centrifugeBaseUrl` | `String` | 心跳 publish API 地址前缀 | `envProvider.centrifugeBaseUrl` | 是 | `postHeartbeat` |
| `centrifugeXApiKey` | `String` | 心跳 API key | `envProvider.centrifugeXApiKey` | 是 | `postHeartbeat` header |

不要在 iSnow 中直接复制 nady 的密钥值；只迁移变量名和读取方式，实际值用 iSnow 的环境配置注入。

## 心跳

房间订阅成功后，`LongLinkManager._startHeartbeat()` 会立即发一次心跳，然后每 30 秒调用一次。

| 字段名 | Dart 类型 | 含义 | 来源 | 是否必填 |
| --- | --- | --- | --- | --- |
| `POST {centrifugeBaseUrl}/api/publish` | `String` | 心跳接口 | `envProvider.centrifugeBaseUrl` | 是 |
| `X-API-Key` | `String` | 心跳鉴权请求头 | `envProvider.centrifugeXApiKey` | 是 |
| `channel` | `String` | 固定值 `heartbeat_channel` | 代码常量 | 是 |
| `data.uid` | `int?` | 当前登录用户 ID | `authenticationUIDProvider.value` | 是 |

## 消息包结构

来源：`/Users/liqihui/nady/lib/model/long_link/long_link_msg.dart`

### `LongLinkMsg<T>`

| 字段名 | Dart 类型 | 含义 | 来源 | 是否必填 | 使用说明 |
| --- | --- | --- | --- | --- | --- |
| `event` | `String` | 事件名 | Centrifugo publication JSON | 是 | 用于匹配 `subscriberMap[event]` |
| `payload` | `T` | 业务负载 | Centrifugo publication JSON | 是 | 实际类型由 event 决定，可能是 `Map` 或 JSON 字符串 |
| `timestamp` | `int` | 服务端时间戳 | Centrifugo publication JSON | 是 | 当前代码主要用于日志/消息顺序 |
| `toType` | `String` | 投递策略 | Centrifugo publication JSON | 是 | 房间公屏中处理 `EXCLUDE_OTHER`、`EXCLUDE_ONESELF` |
| `ids` | `List<String>?` | 目标/排除用户 ID 列表 | Centrifugo publication JSON | 否 | 配合 `toType` 判断是否展示 |
| `msgId` | `String` | 消息 ID | Centrifugo publication JSON | 是 | 写入 `RoomScreenMsg.msgID`，用于本地状态和动画 |
| `from` | `String?` | 来源用户/标识 | Centrifugo publication JSON | 否 | 邀请上麦中作为 inviterUID 使用 |

### `RoomScreenMsg`

| 字段名 | Dart 类型 | 含义 | 来源 | 是否必填 | UI 映射 |
| --- | --- | --- | --- | --- | --- |
| `from` | `BaseUserInfo?` | 发送者用户信息 | socket payload / 本地构造 | 否 | 公屏头像、昵称、等级、装扮 |
| `msg` | `String` | 消息内容或图片路径或 JSON 字符串 | socket payload / 本地构造 | 是 | `NadyChatArea` 消息内容 |
| `event` | `String` | 房间消息事件名 | socket payload / 本地构造 | 是 | 决定公屏 item 类型 |
| `msgID` | `String?` | 消息 ID | `LongLinkMsg.msgId` 或本地时间戳 | 否 | 去更新本地图片发送状态、动画 key |
| `eventId` | `int?` | 通用公屏子类型 | `RoomPublicScreenMsg.event` | 否 | 普通/PK/贵族进房等 |
| `status` | `int?` | 本地图片发送状态 | 本地构造 | 否 | `1` 发送中，`2` 成功，`3` 失败 |
| `targetUid` | `String?` | 目标用户 ID | socket payload / 本地构造 | 否 | party/定向提示 |
| `data` | `dynamic` | 扩展数据 | socket payload / 本地构造 | 否 | 图片、红包、幸运转盘、通用公屏扩展 |

### `RoomScreenGiftMsg`

| 字段名 | Dart 类型 | 含义 | 来源 | 是否必填 | UI 映射 |
| --- | --- | --- | --- | --- | --- |
| `gift` | `RoomMsgGiftModel` | 礼物信息 | `roomScreenSendGiftComboEvent.payload` | 是 | 礼物图标、动画、价格、类型 |
| `count` | `int` | 连击当前次数 | socket payload | 是 | 连击条、飘屏 |
| `giftCount` | `int` | 本次礼物数量 | socket payload | 是 | 动效次数、飘屏展示 |
| `comboCount` | `int` | 连击总数 | socket payload | 是 | 连击按钮/飘屏 |
| `giftSource` | `int` | 礼物来源，`1` 普通，`2` 背包 | socket payload | 是 | 礼物资产/扣费来源 |
| `sendType` | `SendType` | 目标类型 | socket payload | 是 | 单人、麦上、全房 |
| `gold` | `int` | 金币值 | socket payload | 是 | 礼物流水/榜单 |
| `uids` | `List<int>` | 收礼用户 ID 列表 | socket payload | 是 | 麦位礼物弹道 |
| `event` | `String` | 事件名 | socket payload | 是 | 通常对应送礼事件 |
| `uid` | `int` | 送礼人 ID | socket payload | 是 | 本人连击判断 |
| `userInfo` | `BaseUserInfo` | 送礼人信息 | socket payload | 是 | 飘屏发送者 |
| `targetUsers` | `BaseUserInfo?` | 单个收礼人信息 | socket payload | 否 | 飘屏接收者 |

## 频道清单

| 频道 | 订阅类 | 订阅时机 | 事件 |
| --- | --- | --- | --- |
| `global:{uid}` | `LongLinkGlobalUserHandler` | App socket 初始化后 | `GlobalCommonReceiveBadgeEvent`、`UserUploadLogMsg`、`UserBlackListEvent`、`LuckyGiftBigMultiple`、`RoomClosePlayerEvent`、`RoomLobbyBigWinPrizeEvent`、`RoomGameBetAwardEvent` |
| `global` | `LongLinkGlobalHandler` | App socket 初始化后 | `GlobalAristocracyOnlineEvent`，并被座驾控制器动态订阅 `RoomUserPropInfoEvent` |
| `game` | `LongLinkGameHandler` | App socket 初始化后 | `FruitMachineEvent` |
| `game:{uid}` | `LongLinkGameUserHandler` | App socket 初始化后 | `FruitMachineEvent` |
| `room:{roomId}` | `LongLinkRoomIdHandler` | 进入房间后 | 当前房间公屏、麦位、PK、红包、礼物、游戏、身份等事件 |
| `room` | `LongLinkRoomHandler` | 进入房间后 | 全房礼物/游戏/幸运礼物/贵族/世界红包横幅 |
| `global_lobby` | `LongLinkGlobalLobbyHandler` | 游戏广场/大厅需要时 | `RoomLobbyWinEvent`、`RoomLobbyBigWinStatusEvent` |

## 完整事件清单（按事件名）

| 事件常量 | 事件名 | 当前频道/来源 | payload 类型或字段 | 当前处理器 | 对应 UI/状态 |
| --- | --- | --- | --- | --- | --- |
| `roomMicUpdateEvent` | `RoomMicUpdateEvent` | `room:{roomId}` | `RoomMicListModel { micListInfo: List<RoomMicModel> }` | `LongLinkRoomIdHandler.roomMicUpdateEvent` | 更新 `roomMicDataListProvider`、`voiceRoomOnMicUserListProvider`、音乐麦位状态 |
| `roomScreenMessageEvent` | `RoomScreenMessageEvent` | `room:{roomId}` | `RoomScreenMsg` | `screenMessageAndSystemNotice` | 公屏文本消息 |
| `roomScreenEnterRoomMessageEvent` | `RoomScreenEnterRoomMessageEvent` | `room:{roomId}` | `RoomScreenMsg` | `screenMessageAndSystemNotice` | 公屏“加入房间”消息 |
| `roomScreenImageEvent` | `RoomScreenImageEvent` | `room:{roomId}` | `RoomScreenMsg { msg: imagePath }` | `screenImageMessage` | 公屏图片消息；本人发送回推会过滤 |
| `roomScreenSystemNoticeEvent` | `RoomScreenSystemNoticeEvent` | `room:{roomId}` | `RoomScreenMsg` | `screenMessageAndSystemNotice` | 公屏系统通知 |
| `roomScreenExpressionEvent` | `RoomScreenExpressionEvent` | `room:{roomId}` | `RoomScreenMsg { msg: FaceModel JSON }` | `roomScreenExpressionEvent` | 表情消息、公屏 item、麦位表情动画 |
| `roomScreenSendGiftComboEvent` | `roomScreenSendGiftComboEvent` | `room:{roomId}` | `RoomScreenGiftMsg` | `roomScreenSendGiftComboEvent` | 礼物弹道、全屏礼物、连击、全房礼物 |
| `roomMicInviteUpEvent` | `RoomMicInviteUpEvent` | `room:{roomId}` | `Map { uid: int, nick: String }`，`LongLinkMsg.from` 邀请者 | `roomMicInviteUpEvent` | 被邀请用户弹窗，接受后上空闲麦 |
| `roomMicKickOutEvent` | `RoomMicKickOutEvent` | `room:{roomId}` | `Map { uid: int }` | `roomMicKickOutEvent` | 本人被踢下麦提示 |
| `roomConfigUpdateEvent` | `RoomConfigUpdateEvent` | `room:{roomId}` | `RoomUpdateInfoMsg { event, room: RoomInfoLinkModel }` | `roomConfigUpdateEvent` | 更新房间标题、封面、描述、锁房、欢迎语、背景 |
| `roomkickOutEvent` | `RoomKickOutEvent` | `room:{roomId}` | `RoomKickModel { msg?, roomId, from?, event }` | `roomKickOutEvent` | 被踢出房间流程 |
| `roomAudienceUpdateEvent` | `RoomAudienceUpdateEvent` | `room:{roomId}` | `RoomUserTopInfo { roomAudience, audienceCount }` | `roomAudienceUpdateEvent` | 在线人数、前三观众 |
| `roomGiftStreamUpdateEvent` | `RoomGiftStreamUpdateEvent` | `room:{roomId}` | `RoomGiftStreamUpdateModel { roomId, roomWeekVal }` | `roomGiftStreamUpdateEvent` | 房间礼物周流水 |
| `roomIdentityUpdateEvent` | `RoomIdentityUpdateEvent` | `room:{roomId}` | `RoomUserIdentityUpdateModel { uid, roomIdentity, authorityNick? }` | `roomIdentityUpdateEvent` | 本人身份、管理员列表、身份变更弹窗 |
| `roomUserPropInfoEvent` | `RoomUserPropInfoEvent` | `global` 动态订阅 | `Map { roomId, userBaseInfo: BaseUserInfo }` | `RoomVehicleController.onSubscriber` | 进房座驾动画 |
| `roomSendGiftPublicScreenEvent` | `RoomSendGiftPublicScreenEvent` | `room:{roomId}` | JSON 字符串，解析成 `RoomScreenMsg` | `roomSendGiftPublicScreenEvent` | 礼物公屏消息 |
| `roomGiftSendBannerEvent` | `RoomGiftSendBannerEvent` | `room`、`room:{roomId}` 动态订阅 | `GiftBannerPayload` | `GiftBarrageList._addGiftSendBannerEvent` | 礼物顶部横幅 |
| `regularJoyBannerEffectEvent` | `RegularJoyBannerEffectEvent` | `room`、`room:{roomId}` 动态订阅 | `GameBannerPayload` | `GiftBarrageList._addRegularJoyBannerEffectEvent` | 游戏中奖横幅 |
| `roomScreenSystemClear` | `RoomScreenSystemClear` | `room:{roomId}` | `RoomClearnModel { identity, uid, nick }` | `roomScreenSystemClear` | 清空公屏并追加清屏提示 |
| `roomScreenSilenceUpdate` | `RoomUserPublicScreenSilenceUpdate` | `room:{roomId}` | `Map { eventType: int, uid: int, endTime: int }` | `roomScreenSilenceUpdate` | 本人禁言状态、管理列表刷新、toast |
| `userBlack` | `UserBlackListEvent` | `global:{uid}` | `UserShutDownModel` | `LongLinkGlobalUserHandler.onUserBlack` | 强制登出、封禁弹窗 |
| `roomPkInfoUpdate` | `RoomPkInfoUpdate` | `room:{roomId}` | `PkModel` | `roomPkInfoUpdate` | PK 状态、比分、结果层 |
| `roomCustomPublicScreenMsg` | `CustomPublicScreenMsg` | `room:{roomId}` | `RoomPublicScreenMsg { event, textMap, data }` | `roomCustomPublicScreenMsg` | 通用公屏消息 |
| `roomAdjustRoomMicKickOutEvent` | `AdjustRoomMicKickOutEvent` | `room:{roomId}` | `Map { uid: int, hint: String? }` | `roomAdjustRoomMicKickOutEvent` | 麦位布局调整导致本人被挤下麦提示 |
| `userUploadLogMsg` | `UserUploadLogMsg` | `global:{uid}` | `dynamic` | `onUploadLogEvent` | 触发上传日志 |
| `gameModeSwitch` | `RoomModeSwitch` | 仅常量；处理器代码已注释 | `dynamic` | 无 active handler | 保留事件，迁移时可不做首版 |
| `roomInfoUpdateEvent` | `RoomInfoUpdateEvent` | `room:{roomId}` | `RoomInfo { roomInfoDTO: RoomDetailInfo }` | `roomInfoUpdateEvent` | 当前实现实际刷新房间详情 |
| `roomPartyEvent` | `RoomPartyEvent` | `room:{roomId}` | JSON 字符串，解析 `GamePartyModel` | `roomPartyEvent` | 公屏活动/party 消息 |
| `globalCommonReceiveBadgeEvent` | `GlobalCommonReceiveBadgeEvent` | `global:{uid}` | `BadgeModel` 兼容字段 | `onReceiveBadgeEvent` | 勋章弹窗 |
| `luckyGiftSmallMultiple` | `LuckyGiftSmallMultiple` | `room:{roomId}` | `Map { uid: int, awardAmount: int }` | `luckyGiftSmallMultiple` | 本人幸运礼物小倍率金币流动动画 |
| `luckyGiftBigMultiple` | `LuckyGiftBigMultiple` | `global:{uid}` | `LuckBigPayload` | `luckyGiftBigMultiple` | 幸运礼物大倍率全局动效 |
| `roomLuckGiftSendBannerEvent` | `RoomLuckGiftSendBannerEvent` | `room`、`room:{roomId}` 动态订阅 | `LuckBannerPayload` | `GiftBarrageList._addRoomLuckGiftSendBannerEvent` | 幸运礼物横幅 |
| `globalAristocracyOnlineEvent` | `GlobalAristocracyOnlineEvent` | `global` | `NadyAristocracyOnlineData` | `_addGlobalAristocracyOnlineEvent` | 贵族上线全局横幅 |
| `roomAristocracyUpgradeEvent` | `RoomAristocracyUpgradeEvent` | `room` 动态订阅 | `AristocracyUpgradeModel` | `_addRoomAristocracyUpgradeEvent` | 贵族升级全房横幅 |
| `roomScreenLuckyBagSendEvent` | `RoomScreenLuckyBagSendEvent` | `room:{roomId}` | `RoomScreenMsg` | 公屏 handler + `LuckyBagList.roomScreenLuckyBagSendEvent` | 发红包公屏、刷新红包列表 |
| `roomScreenLuckyBagReciveEvent` | `RoomScreenLuckyBagReciveEvent` | `room:{roomId}` | `RoomScreenMsg` | `screenMessageAndSystemNotice` | 抢红包中奖公屏 |
| `roomLuckyBagSettleEvent` | `RoomLuckyBagSettleEvent` | 仅常量；未发现 active subscriber | `dynamic` | 无 active handler | 后端保留/待确认 |
| `worldLuckyBagEvent` | `WorldLuckyBagEvent` | `room` 动态订阅 | `LuckBagBannerPayload` | `_addWorldLuckyBagEvent` | 世界红包横幅 |
| `roomScreenEnterRoomEvent` | `inRoomWelcomeContentEvent` | `room:{roomId}` | `RoomScreenMsg` | `screenMessageAndEnterRoom` | 用户进房欢迎公屏 |
| `luckyWheelInfo` | `LuckyWheelInfo` | `room:{roomId}` | JSON 字符串，解析 `LuckyWheelResult` | `luckyWheelInfo` | 幸运转盘详情/状态刷新 |
| `luckyWheelCancelContent` | `LuckyWheelCancelContent` | `room:{roomId}` | `RoomScreenMsg` | `luckyWheelCancelContent` | 幸运转盘取消公屏、关闭弹窗 |
| `luckyWheelStartContent` | `LuckyWheelStartContent` | `room:{roomId}` | `RoomScreenMsg` | `luckyWheelStartContent` | 幸运转盘开始公屏、打开弹窗 |
| `roomMicCharmIsEnableEvent` | `RoomMicCharmIsEnableEvent` | `room:{roomId}` 动态订阅 | `bool` | `CharmStatus.onRoomMicCharmIsEnableEvent` | 麦位魅力值显示开关 |
| `fruitMachineEvent` | `FruitMachineEvent` | `game`、`game:{uid}` | `dynamic` | `fruitMachineEvent` | `gameInfoStateProvider`，通知 H5 游戏 |
| `roomGameAwardEvent` | `RoomGameAwardEvent` | `room:{roomId}` | `RoomGameAwardModel` | `roomGameAwardEventContent` | 房间游戏奖励动画、游戏记录插入 |
| `roomGameAwardEvent2` | `RoomGameAwardEvent2` | `room:{roomId}` | `RoomGameAwardModel` | `roomGameAwardEventContent2` | 挖矿游戏奖励动画、挖矿记录插入 |
| `roomLobbyStatusEvent` | `RoomLobbyStatusEvent` | `room:{roomId}` | `Map { status: int, lobbyType?: int }` | `roomLobbyStatusEvent` | 房间游戏大厅开关、麦位区域模式 |
| `roomLobbyWinEvent` | `RoomLobbyWinEvent` | `global_lobby` | JSON 字符串 -> `Map<String, dynamic>` | `roomLobbyWinEvent` | 游戏广场中奖列表插入 |
| `roomClosePlayerEvent` | `RoomClosePlayerEvent` | `global:{uid}` | `dynamic` | `roomClosePlayerEvent` | 关闭房间音乐播放器，停止 Agora 混音 |
| `roomLobbyBigWinStatusEvent` | `RoomLobbyBigWinStatusEvent` | `global_lobby` | `RoomLobbyBigWinPushModel` | `roomLobbyBigWinStatusEvent` | 大奖状态、大奖顶部通知 |
| `roomLobbyBigWinPrizeEvent` | `RoomLobbyBigWinPrizeEvent` | `global:{uid}` | `dynamic Map` | `roomLobbyBigWinPrizeEvent` | 大奖中奖数据 |
| `roomGameBetAwardEvent` | `RoomGameBetAwardEvent` | `global:{uid}` | `dynamic Map` | `roomGameBetAwardEvent` | 游戏周流水奖励状态 |

## 事件清单（按房间功能）

### 公屏消息

| 功能 | 事件 | 发送/触发 | 接收后状态 |
| --- | --- | --- | --- |
| 文本消息 | `RoomScreenMessageEvent` | `POST /api/room/msg/push`，`SendRoomMsgRequest.event` | `RoomMsg.addMsg(RoomScreenMsg)` |
| 进房消息 | `RoomScreenEnterRoomMessageEvent` | `RoomMsg.sendEnterRoomMsg()` | `RoomMsg.addMsg` |
| 用户进房欢迎 | `inRoomWelcomeContentEvent` | 订阅 `room:{roomId}` 成功后调用 `/api/room/inRoom/sendScreen` | `RoomMsg.addMsg` |
| 图片消息 | `RoomScreenImageEvent` | OSS 上传后 `POST /api/room/msg/push` | `RoomMsg.addMsg`，本人回推过滤 |
| 系统通知 | `RoomScreenSystemNoticeEvent` | 后端推送 | `RoomMsg.addMsg` |
| 表情 | `RoomScreenExpressionEvent` | 表情发送接口同消息接口 | 公屏 item + 麦位表情动画 |
| 送礼公屏 | `RoomSendGiftPublicScreenEvent` | `/api/gift/send` 后端回推 | 公屏礼物 item |
| 通用公屏 | `CustomPublicScreenMsg` | 后端推送 | `RoomPublicScreenMsg` -> `RoomScreenMsg` |
| 清屏 | `RoomScreenSystemClear` | `/api/room/clean` 后端回推 | 清空 `RoomMsg` 后插入清屏提示 |
| party | `RoomPartyEvent` | 活动/party 后端推送 | 公屏 party item |

### 麦位与 RTC

| 功能 | 事件/API | payload/请求字段 | 接收后状态 |
| --- | --- | --- | --- |
| 麦位列表刷新 | `RoomMicUpdateEvent` | `micListInfo: List<RoomMicModel>` | `roomMicDataListProvider.refresh` |
| 邀请上麦 | `RoomMicInviteUpEvent` | `uid`、`nick`、`from` | 被邀请用户弹窗；确认后调用 `upMicLeisureMic` |
| 踢下麦 | `RoomMicKickOutEvent` | `uid` | 本人被踢提示 |
| 调整麦位挤下麦 | `AdjustRoomMicKickOutEvent` | `uid`、`hint` | 本人提示 |
| 魅力值开关 | `RoomMicCharmIsEnableEvent` | `bool` | `CharmStatus.state` |

### 房间信息和身份

| 功能 | 事件/API | payload/请求字段 | 接收后状态 |
| --- | --- | --- | --- |
| 房间配置更新 | `RoomConfigUpdateEvent` | `RoomUpdateInfoMsg` | 更新标题、封面、房锁、欢迎语、背景 |
| 房间详情更新 | `RoomInfoUpdateEvent` | `RoomInfo` | 重新拉取房间详情 |
| 房间身份更新 | `RoomIdentityUpdateEvent` | `uid`、`roomIdentity`、`authorityNick` | 更新本人身份、刷新管理员 |
| 观众数/前三 | `RoomAudienceUpdateEvent` | `RoomUserTopInfo` | 在线人数和前三观众 |
| 礼物流水 | `RoomGiftStreamUpdateEvent` | `roomId`、`roomWeekVal` | 房间周流水 |
| 踢出房间 | `RoomKickOutEvent` | `RoomKickModel` | 退房/弹窗 |

### 礼物、横幅和特效

| 功能 | 事件/API | payload | 接收后状态 |
| --- | --- | --- | --- |
| 礼物发送结果 | `roomScreenSendGiftComboEvent` | `RoomScreenGiftMsg` | 触发礼物弹道、飘屏、全屏动画、连击 |
| 礼物横幅 | `RoomGiftSendBannerEvent` | `GiftBannerPayload` | 顶部礼物横幅 |
| 游戏横幅 | `RegularJoyBannerEffectEvent` | `GameBannerPayload` | 顶部游戏横幅 |
| 幸运礼物小倍率 | `LuckyGiftSmallMultiple` | `uid`、`awardAmount` | 本人金币流动动画 |
| 幸运礼物大倍率 | `LuckyGiftBigMultiple` | `LuckBigPayload` | 全局大倍率动效 |
| 幸运礼物横幅 | `RoomLuckGiftSendBannerEvent` | `LuckBannerPayload` | 顶部幸运礼物横幅 |
| 贵族上线 | `GlobalAristocracyOnlineEvent` | `NadyAristocracyOnlineData` | 全局贵族上线横幅 |
| 贵族升级 | `RoomAristocracyUpgradeEvent` | `AristocracyUpgradeModel` | 全房贵族升级横幅 |
| 座驾 | `RoomUserPropInfoEvent` | `roomId`、`userBaseInfo` | 进房座驾动画 |

### 红包、幸运转盘和游戏

| 功能 | 事件/API | payload | 接收后状态 |
| --- | --- | --- | --- |
| 房间红包发送公屏 | `RoomScreenLuckyBagSendEvent` | `RoomScreenMsg` | 公屏消息 + 刷新红包列表 |
| 抢红包中奖公屏 | `RoomScreenLuckyBagReciveEvent` | `RoomScreenMsg` | 公屏消息 |
| 世界红包横幅 | `WorldLuckyBagEvent` | `LuckBagBannerPayload` | 顶部世界红包横幅 |
| 红包结算 | `RoomLuckyBagSettleEvent` | 未发现 active handler | 首版可先保留常量 |
| 幸运转盘状态 | `LuckyWheelInfo` | `LuckyWheelResult` JSON 字符串 | 刷新转盘详情、关闭弹窗或展示结果 |
| 幸运转盘取消 | `LuckyWheelCancelContent` | `RoomScreenMsg` | 关闭转盘弹窗、公屏消息 |
| 幸运转盘开始 | `LuckyWheelStartContent` | `RoomScreenMsg` | 打开转盘弹窗、公屏消息 |
| H5 游戏 | `FruitMachineEvent` | `dynamic` | `gameInfoStateProvider.set({event, payload})` |
| 游戏奖励 | `RoomGameAwardEvent` | `RoomGameAwardModel` | 默认游戏奖励动画、记录插入 |
| 挖矿奖励 | `RoomGameAwardEvent2` | `RoomGameAwardModel` | 挖矿奖励动画、记录插入 |
| 房间大厅开关 | `RoomLobbyStatusEvent` | `status`、`lobbyType` | 麦位区域游戏模式 |
| 大厅中奖 | `RoomLobbyWinEvent` | JSON 字符串 -> Map | 游戏广场记录 |
| 大奖状态 | `RoomLobbyBigWinStatusEvent` | `RoomLobbyBigWinPushModel` | 大奖状态和通知 |
| 大奖中奖 | `RoomLobbyBigWinPrizeEvent` | Map | 大奖中奖数据 |
| 周流水奖励 | `RoomGameBetAwardEvent` | Map | 周流水奖励状态 |

## 事件分发建议

当前 `LongLinkHandler` 是“一频道一个 subscription + subscriberMap 精确匹配 event”。迁移到 iSnow 时建议保持类似结构，但把业务处理从 socket 层移出。

```dart
typedef SocketEventCallback = void Function(SocketMessage message);

class SocketMessage {
  const SocketMessage({
    required this.event,
    required this.payload,
    required this.timestamp,
    required this.toType,
    required this.msgId,
    this.ids,
    this.from,
    this.channel,
  });

  final String event;
  final Object? payload;
  final int timestamp;
  final String toType;
  final List<String>? ids;
  final String msgId;
  final String? from;
  final String? channel;
}

class SocketEventBus {
  final Map<String, List<SocketEventCallback>> _handlers = {};

  void on(String event, SocketEventCallback callback) {
    _handlers.putIfAbsent(event, () => <SocketEventCallback>[]).add(callback);
  }

  void off(String event, SocketEventCallback callback) {
    _handlers[event]?.remove(callback);
  }

  void emit(SocketMessage message) {
    final callbacks = List<SocketEventCallback>.from(_handlers[message.event] ?? const []);
    for (final callback in callbacks) {
      callback(message);
    }
  }
}
```

## `AppSocketManager` 骨架

```dart
enum AppSocketStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class AppSocketManager {
  AppSocketManager({
    required this.api,
    required this.env,
    required this.currentUidProvider,
    required this.eventBus,
  });

  final SocketApi api;
  final SocketEnv env;
  final int? Function() currentUidProvider;
  final SocketEventBus eventBus;

  Object? _client;
  final Map<String, Object> _subscriptions = {};
  Timer? _heartbeatTimer;
  AppSocketStatus status = AppSocketStatus.idle;
  String? currentRoomId;

  Future<void> connect() async {
    status = AppSocketStatus.connecting;
    final url = await api.getLongLinkUrl();
    final token = await api.getConnectionToken();
    // TODO(iSnow): create Centrifugo client with url and token callback.
    // TODO(iSnow): bind connected/disconnected/error/reconnecting callbacks.
    status = AppSocketStatus.connected;
    await subscribeGlobalChannels();
  }

  Future<void> subscribeGlobalChannels() async {
    final uid = currentUidProvider();
    if (uid == null) return;

    await subscribeChannel('global');
    await subscribeChannel('global:$uid');
    await subscribeChannel('game');
    await subscribeChannel('game:$uid');
  }

  Future<void> joinRoom(String roomId) async {
    currentRoomId = roomId;
    await subscribeChannel('room:$roomId');
    await subscribeChannel('room');
    startHeartbeat();
  }

  Future<void> leaveRoom(String roomId) async {
    await unsubscribeChannel('room:$roomId');
    await unsubscribeChannel('room');
    if (currentRoomId == roomId) {
      currentRoomId = null;
    }
    stopHeartbeat();
  }

  Future<void> subscribeGlobalLobby() async {
    await subscribeChannel('global_lobby');
  }

  Future<void> unsubscribeGlobalLobby() async {
    await unsubscribeChannel('global_lobby');
  }

  Future<void> subscribeChannel(String channel) async {
    if (_subscriptions.containsKey(channel)) {
      await unsubscribeChannel(channel);
    }

    final token = await api.getChannelToken(channel);
    // TODO(iSnow): create subscription with channel token callback.
    // TODO(iSnow): decode publication bytes to SocketMessage.
    // TODO(iSnow): eventBus.emit(message).
    _subscriptions[channel] = Object();
  }

  Future<void> unsubscribeChannel(String channel) async {
    final subscription = _subscriptions.remove(channel);
    if (subscription == null) return;
    // TODO(iSnow): unsubscribe and remove from client.
  }

  Future<void> handleReconnectSuccess() async {
    final roomId = currentRoomId;
    if (roomId == null || roomId.isEmpty) return;
    await api.reportRoomReconnect(roomId);
  }

  void startHeartbeat() {
    if (_heartbeatTimer?.isActive ?? false) return;
    postHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      postHeartbeat();
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> postHeartbeat() async {
    final uid = currentUidProvider();
    if (uid == null) return;
    await api.publishHeartbeat(
      baseUrl: env.centrifugeBaseUrl,
      apiKey: env.centrifugeXApiKey,
      uid: uid,
    );
  }

  Future<void> disconnect() async {
    stopHeartbeat();
    for (final channel in List<String>.from(_subscriptions.keys)) {
      await unsubscribeChannel(channel);
    }
    // TODO(iSnow): disconnect client.
    status = AppSocketStatus.disconnected;
  }
}
```

## Socket API 骨架

```dart
class SocketApi {
  SocketApi(this.http);

  final HttpClient http;

  Future<String> getLongLinkUrl() async {
    return http.getString('/config/long-link-url');
  }

  Future<String> getConnectionToken() async {
    return http.getString('/token/long-link');
  }

  Future<String> getChannelToken(String channel) async {
    return http.getString(
      '/api/room/genGlobalToken',
      query: {'channel': channel},
    );
  }

  Future<void> reportRoomReconnect(String roomId) async {
    await http.post('/api/room/reconnect/report', body: {
      'roomId': roomId,
    });
  }

  Future<void> publishHeartbeat({
    required String baseUrl,
    required String apiKey,
    required int uid,
  }) async {
    await http.postAbsolute(
      '$baseUrl/api/publish',
      headers: {'X-API-Key': apiKey},
      body: {
        'channel': 'heartbeat_channel',
        'data': {'uid': uid},
      },
    );
  }
}
```

## 事件 adapter 骨架

```dart
class RoomSocketEventAdapter {
  RoomSocketEventAdapter({
    required this.eventBus,
    required this.roomManager,
  });

  final SocketEventBus eventBus;
  final RoomManager roomManager;

  void bind() {
    eventBus.on(RoomSocketEvents.roomMicUpdateEvent, _onMicUpdate);
    eventBus.on(RoomSocketEvents.roomScreenMessageEvent, _onRoomScreenMessage);
    eventBus.on(RoomSocketEvents.roomScreenImageEvent, _onRoomScreenImage);
    eventBus.on(RoomSocketEvents.roomScreenExpressionEvent, _onExpression);
    eventBus.on(RoomSocketEvents.roomScreenSendGiftComboEvent, _onGift);
    eventBus.on(RoomSocketEvents.roomIdentityUpdateEvent, _onIdentityUpdate);
    eventBus.on(RoomSocketEvents.roomKickOutEvent, _onKickOut);
    eventBus.on(RoomSocketEvents.roomPkInfoUpdate, _onPkUpdate);
    eventBus.on(RoomSocketEvents.roomLobbyStatusEvent, _onLobbyStatus);
  }

  void unbind() {
    eventBus.off(RoomSocketEvents.roomMicUpdateEvent, _onMicUpdate);
    eventBus.off(RoomSocketEvents.roomScreenMessageEvent, _onRoomScreenMessage);
    eventBus.off(RoomSocketEvents.roomScreenImageEvent, _onRoomScreenImage);
    eventBus.off(RoomSocketEvents.roomScreenExpressionEvent, _onExpression);
    eventBus.off(RoomSocketEvents.roomScreenSendGiftComboEvent, _onGift);
    eventBus.off(RoomSocketEvents.roomIdentityUpdateEvent, _onIdentityUpdate);
    eventBus.off(RoomSocketEvents.roomKickOutEvent, _onKickOut);
    eventBus.off(RoomSocketEvents.roomPkInfoUpdate, _onPkUpdate);
    eventBus.off(RoomSocketEvents.roomLobbyStatusEvent, _onLobbyStatus);
  }

  bool _canRender(SocketMessage message) {
    final uid = roomManager.currentUid?.toString();
    if (message.toType == 'EXCLUDE_ONESELF') return false;
    if (message.toType == 'EXCLUDE_OTHER') {
      return uid != null && (message.ids ?? const <String>[]).contains(uid);
    }
    return true;
  }

  void _onMicUpdate(SocketMessage message) {
    final data = RoomMicListModel.fromJson(asMap(message.payload));
    roomManager.updateMicList(data.micListInfo);
  }

  void _onRoomScreenMessage(SocketMessage message) {
    if (!_canRender(message)) return;
    roomManager.addScreenMessage(RoomScreenMsg.fromJson(asMap(message.payload)).copyWith(
      msgID: message.msgId,
    ));
  }

  void _onRoomScreenImage(SocketMessage message) {
    if (!_canRender(message)) return;
    final data = RoomScreenMsg.fromJson(asMap(message.payload)).copyWith(msgID: message.msgId);
    if (data.from?.uid == roomManager.currentUid) return;
    roomManager.addScreenMessage(data);
  }

  void _onExpression(SocketMessage message) {
    final data = RoomScreenMsg.fromJson(asMap(message.payload)).copyWith(msgID: message.msgId);
    roomManager.addScreenMessage(data);
    roomManager.addMicExpression(data);
  }

  void _onGift(SocketMessage message) {
    roomManager.receiveGift(RoomScreenGiftMsg.fromJson(asMap(message.payload)));
  }

  void _onIdentityUpdate(SocketMessage message) {
    roomManager.updateIdentity(RoomUserIdentityUpdateModel.fromJson(asMap(message.payload)));
  }

  void _onKickOut(SocketMessage message) {
    roomManager.handleKickOut(RoomKickModel.fromJson(asMap(message.payload)));
  }

  void _onPkUpdate(SocketMessage message) {
    roomManager.updatePk(PkModel.fromJson(asMap(message.payload)));
  }

  void _onLobbyStatus(SocketMessage message) {
    final payload = asMap(message.payload);
    roomManager.updateLobbyStatus(
      status: payload['status'] as int? ?? 0,
      lobbyType: payload['lobbyType'] as int? ?? 1,
    );
  }

  Map<String, dynamic> asMap(Object? payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is String) return jsonDecode(payload) as Map<String, dynamic>;
    return <String, dynamic>{};
  }
}
```

## 迁移验收点

| 验收点 | 判断方式 |
| --- | --- |
| App 启动后全局 socket 可连接 | `global`、`global:{uid}`、`game`、`game:{uid}` 已订阅 |
| 进入房间后订阅房间频道 | `room:{roomId}` 和 `room` 已订阅，心跳每 30 秒发送 |
| 断线重连上报 | socket reconnect 成功后调用 `/api/room/reconnect/report` |
| 事件分发不耦合 UI | socket 层只 emit，RoomManager 或 feature adapter 处理业务 |
| payload 类型兼容 | 对 `Map` 和 JSON 字符串 payload 都有 adapter |
| 退出房间清理 | `room:{roomId}`、`room` 退订，心跳停止，保留全局频道 |
