# Room Gift Flow Implementation

实现依据：`prd/room_gift_flow_v1.0.md`。业务请求继续使用原有
`HttpApi.giftSend` 和 `HttpDioManager`，未改变后端接口或增加第二套业务网络层。

## Data Flow

`RoomGiftViewModel -> RoomGiftSendController -> RoomGiftRepository`

`RoomRepository.socketMessages -> RoomGiftEventManager -> typed render states`

- 面板与卡槽共用房间级发送控制器，统一锁定请求。HTTP 成功扣减本地余额或背包，并使用返回的 comboId 开放 Combo；不创建收礼事件。
- 首次发送使用空 comboId / comboCount=1；后续点击沿用成功回执的 comboId。与 Nady 一致，comboCount 表示本次请求的点击次数，单次点击发送 1，不发送广播中的累计次数；等待 HTTP 完成后才允许下一次点击，不自动重试。
- 发送前重新读取当前麦位与在线人数；过滤无效 UID 和禁止赠送的自己。背包必须有 userBackpackId，库存按每人数量乘目标人数扣减。
- 支持 sendType 1/2/3/4/6，其中 4 保留 ViewModel/API 兼容入口；原有面板仍展示单选/多选、全麦、全房选项。

## Events And Queues

- PRD 中九种事件均有统一解析入口，包括 Nady combo 结束消息的嵌套 JSON 字符串。
- 全局 room 频道要求显式匹配 roomId；指定房间频道可推断房间。错误房间、缺少必要业务数据、损坏 JSON 会记录诊断并丢弃，不影响 Socket。
- 公屏按 combo 更新同一条记录，结束消息覆盖最终数量与中奖结果。
- 房间 ViewModel 只同步新增或变化的公屏数据，不在周期清理时重新插入已被聊天记录淘汰的旧礼物；恢复房间时重新读取现有公屏快照。
- 卡槽仅两条，首次出现本人数据的槽位会保持绑定；其他用户不覆盖本人槽位。同 combo 原位更新，5 秒过期、2 秒清理。
- 公屏最多 80 条、飞行事件最多 32 条、全屏/横幅最多 12 条、幸运结果最多 8 条；全屏保留正在播放的队首，容量满时替换等待项。
- msgId 去重窗口 2 分钟、上限 300；combo 最新版本和已结束 combo 有界保存。后台、最小化、重连时清空视觉队列并设置时间门槛，不补播已过期事件。
- RoomGiftStreamUpdateEvent 独立更新周流水，最小化时仍接收数据。

## Visual Layers

- 公屏：头像、礼物图片、名称、累计数量、接收目标、最终中奖金币；兼容 Nady 的 RoomSendGiftComboPublicScreenEvent 文本消息。
- 卡槽：原生入数缩放动画、累计数量和服务端确认的 Combo 入口。广播未到达或卡槽已过期时，已确认的 Combo 单独显示在房间右下角；出现匹配卡槽后只保留卡槽中的入口，不重复展示。
- 轨迹：在 RoomPage Stack 的局部坐标内注册麦位头像中心；按目标拆分原生曲线动画。发送人不在麦位上时使用底部礼物按钮中心作为起点；目标坐标缺失跳过，麦位移动/离开时取消，结束/销毁释放 controller。
- 横幅：独立滑入、计时队列；支持服务端 bannerEffectUrl/effectUrl 和 upperEffect。
- 幸运结果：只展示累计值增量，遵守隐藏标记及 playWinGoldCount；支持小/大倍率、Jackpot、本地 Nady VAP 背景。
- 全屏：SVGA、PAG、普通 MP4（animationType=6）、透明 VAP 与原生静态礼物降级。播放失败或结束推进下一项，播放器有 25 秒看门狗。
- 卡槽区域在聊天区域内预留空间；多麦位/小屏时可滚动，避免新卡槽挤压整个房间 Column 导致溢出。

## Resource Handling

- 本地映射集中在 AppAssets；Nady 本地动效与来源记录在 assets/room_gift/manifest.json。
- CDN 动画使用独立文件缓存，14 天、最多 60 文件、文件大小限制 32 MiB；获取等待最多 15 秒。该资源缓存不携带 Nady 登录凭证。
- 图片使用现有 cached_network_image；资源缺失继续使用红色缺省图，没有新增 Flutter Icon。
- 播放库采用 Nady 已使用的可移植源码副本，兼容变更及许可证见 packages/README.md。

## Verification

- 模型、发送参数/扣费/库存、请求锁、HTTP/Socket 回执乱序、连送、事件去重、主客态、错误房间、后台重播、轨迹与资源失败推进均有测试。
- 礼物面板及动效层提供 320/375 像素截图基线；面板另有 430 像素布局检查。
- 包含房间公屏与聊天混排的回归测试：旧礼物不重新插入、连击更新不改变列表位置。
- 2026-10-05 验证：送礼相关 51 项测试通过，flutter analyze 无问题，Android debug APK 构建通过。
- 运行方式：`flutter test test/room_gift_*_test.dart`、`flutter analyze`、`flutter build apk --debug -t lib/lib_dev.dart`。
- 实际收费送礼、多设备广播与 iOS 原生播放仍需要测试账号/真机验收；自动化测试不会向真实账户发起扣费请求。
- 全量测试中已有的 login_detail_page_test 默认区号 +996 断言失败与本次修改无关，未修改登录流程。

## Send Button Fix (2026-10-07)

- Nady 房间详情中的在线人数可能使用 `onlineNum`。RoomInfo 统一兼容 `audienceCount`、`roomAudience`、`onlineNum`、`inRoomNum`，包括嵌套房间信息和外层人数，防止发送前读取实时数据时误把全房目标数量变为 0；显式的 0 不会被其他字段覆盖。
- 发送校验和接口错误直接显示在面板底部，不再依赖被 ModalBottomSheet 遮挡的房间 SnackBar。请求失败保留面板与余额，成功才关闭面板。
- 开发模式的 `[RoomGiftSend][roomId]` 日志区分 `blocked`、`submit`、`success`、`failed`，提交日志包含目标模式、每人数量、目标人数及总价，不包含鉴权信息。
- 新增在线人数解析、真实面板点击 Send、目标失效、服务端错误以及请求期间关闭面板的回归测试。送礼和房间模型相关共 60 项测试通过，原有 320/375 面板截图基线保持不变；未向真实账号发起扣费请求。

## Successful Send Feedback Fix (2026-10-08)

- 根因之一是忽略 `/api/gift/send` 返回的字符串 comboId，而且 Combo 只挂在广播卡槽上。现在 HTTP 成功即开放独立连击入口，不依赖 Socket 回包，也不伪造公屏、卡槽或礼物动效。缺少 HTTP comboId 时仍可使用匹配的本人广播回执。
- 默认 Socket 地址改为通过 `HttpApi.longLinkUrl` 请求 `/config/long-link-url`，与 Nady 使用同一 API 环境的连接配置；不再从网站域名拼接 `/connection/websocket`。显式传入的测试地址仍可覆盖配置。
- 持续监听 SDK 的 connecting/subscribing/subscribed/unsubscribed，房间频道恢复订阅即恢复 ready；可选全局 room 频道失败不影响当前房间。退房时同时从 SDK 移除订阅，保证同房间再次进入可重新订阅。
- 房间前台可见状态与 Socket ready 分离，避免已确认的连击按钮因为连接尚未就绪而隐藏。断线仍清空视觉队列和旧连击，最小化/后台/退房仍停止展示，不补播历史事件。
- 开发模式日志：`[RoomSocket]` 显示安全的 endpoint、状态、频道、event、msgId、时间戳和 payload 类型；`[RoomGift][roomId]` 显示接收、重复、不可见、过期和解析失败原因；`[RoomGiftSend][roomId] confirmed` 显示 HTTP 确认的 comboId。日志不输出鉴权 token 或完整用户 payload。
- 补充 Socket 地址、失败、同房重入、重连后公屏/动效分发、HTTP 独立连击、重复点击锁、320/375 连击布局、非麦位起点及 Nady 文本公屏测试。真机送礼及跨设备广播仍需实际账号验证，自动化不会触发真实扣费。
- 本次验证：礼物、房间模型与 Socket 相关 75 项测试通过，原有 320/375 截图基线通过，`flutter analyze --no-pub` 无问题。
