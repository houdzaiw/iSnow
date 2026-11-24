# Lucky Box 单次真实发送验收

2026-11-22，用户单独授权：Pixel_9账号30317291在hei2（展示12594212）发送一次Room宝箱，总额5,000金币、2个领取名额、倒计时60秒，费用上限5,000金币；结果不明不得重发，禁止点击Open或领取。该授权已消耗，不延续到下一次发送或任何领取。

## 执行与扣币

- 两端真实roomId均为`2113281922745016322`，发送端UID30317291、第二端UID12594212，Room／Socket均ready，保留原两个麦位。全过程未重启、重装或热重载。
- 打开面板时余额读取发生一次连接提前关闭，发送按钮按预期禁用；尚未点击Send。仅点击一次读取重试，取得新的成功余额及配置后，按钮恢复可用，不以旧余额绕过校验。
- 核对Room／5,000／2人／60秒及页面`Send · 5000`，只点击一次Send，再在显示5,000金币的确认框中确认一次。
- 只有一笔`POST /api/redPacket/push`，请求为`{roomId:2113281922745016322,type:0,gold:5000,numberOfRecipients:2,countdown:60}`，与Nady `services/api/room_api.dart` 的字段和方法一致。
- HTTP200／业务200，traceId `26cb0966-438d-495f-8e95-a736057cc492`，宝箱ID `bf65742d283c4261b64a97a27a917d34`。
- 真实钱包金币从49,855,108变为49,850,108，恰好扣除5,000；钻石保持35,338。第二端金币保持4。没有重发或额外礼物消费。

## 两端结果

- 两端收到相同的`RoomScreenLuckyBagSendEvent`，msgId `e7f9dd49d7d54808bc3eeb6700e4c4a5`。列表中均出现该发送者宝箱，没有重复插入。
- 列表画面已核对倒计时从0:43至0:01，随后两端均为0:00；关闭列表后出现领取前提示。只关闭提示，不点击Open。两端`POST /api/redPacket/grab`均为0，未产生奖品或领取结果。
- 关闭第二端提示时意外打开了房间退出确认框，随后用返回取消，没有选择Keep或Exit；最终仍在原房间，房间代次及两个麦位不变。保留画面证据，不将退出确认框截图标为普通房间画面。
- 未发送聊天消息、开始／结束PK、上下麦、切房或切换大厅模式；日志中无新增未处理Flutter异常。本轮未改生产代码，不将历史自动化结果冒充本次真实验收。

## 本轮发现与待办

1. **发送回执时间字段不一致。** push响应返回`remainingTime=359`、deadline约为发送后360秒；随后list对同一ID返回`remainingTime=57`、deadline `1795346726000`（发送约60秒后）。当前发送流程以重新读取的列表更新状态，两端实际按一分钟归零，不需要再发宝箱。保留原回执，需服务端核对push DTO；不能将359秒直接作为新的UI时间源。
2. **宝箱公屏HTML未解析。** 实际文案显示了`<p>`、`<span style=...>`标签。`RoomScreenLuckyBagSendEvent`被映射为gift消息，需要为这类服务端富文本复用安全解析，并保留已核对的消息ID去重；不要通过再次发送复现，已有真实消息可用于只读验证。本轮记录为未通过项，尚未修改。
3. **规则图币种文案仍不一致。** 原服务端图片写diamonds，实际本次扣的是金币；本轮真实钱包响应已确认，仍需更新规则素材。
4. **关闭按钮命中需补查。** 第二端关闭到时提示后出现退出确认框，原因尚未确认；只读复查关闭层级和点击命中，避免影响房间退出入口。

真实领取、中奖／未中奖、奖品到账和领取动效均未验收，必须针对具体账号和该宝箱另行确认；本次不包含自动领取或自动发送下一箱。

## 证据

- [请求、回执、余额及两端最终状态](verification.json)。其中仅保存脱敏后的接口分类和业务字段，不保存鉴权头、调试地址或完整原始日志。
- [发送前参数](preflight-retry.png)、[单次扣费确认](send-confirmation.png)。
- [发送后公屏与待修复HTML](after-send-pixel.png)、[第二端收到宝箱](after-send-owner.png)。
- [Pixel_9倒计时](pixel-list-countdown.png)、[第二端倒计时](owner-list-countdown.png)、[Pixel_9归零](pixel-list-ready.png)、[第二端归零](owner-list-ready.png)。
- [Pixel_9领取前提示](pixel-ready-prompt.png)、[第二端领取前提示](owner-ready-prompt.png)，均未点击Open。
- [Pixel_9关闭后](pixel-closed-without-grab.png)、[第二端误开的退出确认](owner-exit-dialog-before-cancel.png)、[取消后最终房间](owner-final-room.png)。这些是运行证据，不是截图测试基线。
