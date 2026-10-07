# Room Gift Flow Implementation

实现依据：`prd/room_gift_flow_v1.0.md`。业务请求继续使用原有
`HttpApi.giftSend` 和 `HttpDioManager`，未改变后端接口或增加第二套业务网络层。

## Data Flow

`RoomGiftViewModel -> RoomGiftSendController -> RoomGiftRepository`

`RoomRepository.socketMessages -> RoomGiftEventManager -> typed render states`

- 面板与卡槽共用房间级发送控制器，统一锁定请求。HTTP 成功仅扣减本地余额或背包；不创建收礼事件。
- 首次发送使用空 comboId / comboCount=1；服务端本人广播确认后，卡槽才开放 Combo 按钮。下一次发送等待新的服务端次数回执，不自动重试。
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

- 公屏：头像、礼物图片、名称、累计数量、接收目标、最终中奖金币。
- 卡槽：原生入数缩放动画、累计数量和服务端确认的 Combo 入口。
- 轨迹：在 RoomPage Stack 的局部坐标内注册麦位头像中心；按目标拆分原生曲线动画。坐标缺失跳过，麦位移动/离开时取消，结束/销毁释放 controller。
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
