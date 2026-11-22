# 礼物面板首充与活动条

## 规则与来源

本轮对照 Nady `widgets/gift_panel/gift_panel_widget.dart`、`nady_gift_banner.dart`、`pages/main/sub_pages/me/purse/first_gift_pack_data.dart` 和支付 Provider 修正。

- 首充图片入口只在 `/api/revenue/purse` 明确返回 `isFirst=true` 时显示。未知、缺字段、刷新失败或非首充均隐藏，不能根据余额推断资格。
- 复用礼物余额请求读取资格；加载缓存时重新核对钱包，不额外重复请求目录。保留余额版本及账号隔离。
- 首充点击关闭礼物面板，打开独立礼包弹层，不跳普通 Wallet。底部金币余额仍打开原 Wallet。
- 礼物活动只显示所选礼物的真实 `banner`；没有 banner 时不展示静态示例活动图。首充和 banner 均不存在时整行收起，同时缩短面板高度，礼物网格空间不变。
- 有 banner、没有有效 HTTP(S) `jumpLink` 时仅展示图片。有效链接沿用 `Uri` 合并 language，保留其他参数；重复点击和过期房间会话不再导航。

## 礼包与支付

独立模块在 `lib/classes/room/gift/recharge/`，使用 Model、Repository、ViewModel 和 View 分层；视觉参数集中到 `RoomFirstRechargeTheme`。

| 用途 | 接口或规则 |
| --- | --- |
| 首充资格 | GET `/api/revenue/purse`，读取 `isFirst` |
| 首充礼包 | GET `/api/recharge/package/giftBag`，无自造参数，按 sortNo 排序 |
| 可购买状态 | Nady 的 `isBuy=true` 表示可购买，不是已经买过 |
| 价格 | dollarAmount、originalPrice 按美分展示 USD；实际商店确认页继续由 Google 提供 |
| 奖励 | rewardPack.resourceVOList，读取数量、天数或永久有效；无图使用红色缺省图 |
| 购买 | 保留礼包原 id，复用 WalletViewModel、Google 创建订单、buyConsumable 和已有订单回调处理 |

打开礼包页只加载钱包和礼包，不创建支付监听、不初始化内购或恢复历史订单。用户主动购买时再次核对资格和套餐，才启动共享支付能力；等待已有恢复流程完成后发起新结算。重复点击合并，已有待处理结算时禁止新结算。关闭或切换房间、账号后，尚未拉起的商店操作作废；已经交给商店的回执继续由共享支付控制器处理，不回写已关闭视图。

支付取消和失败保留礼包及重试入口；错误优先使用服务端 msg。收到商店成功回调后重新读取服务端资格／套餐：未确认完成时禁用再次购买，提供手动查询，不自动重复扣费。服务端确认后通知余额相关 Provider 刷新。网络失败与购买成功反馈分开，不把未知结果解释为可立即重新支付。

## 验证边界

自动化覆盖资格未知／非首充、无 banner、展示但无链接、真实 banner 点击、320／375／430 宽度、礼包解析、接口参数、资格变化、重复操作、取消与异常、关闭和账号／房间切换隔离、旧订单恢复及共享支付监听释放。原活动 URL 语言参数校验继续回归。

礼物面板历史 `room_gift_panel_v3` 截图保留，移除示例活动条后的截图独立放在 `room_gift_panel_v4`。捕获前等待实际图片解码，避免将冷缓存空图写进新版基线。

本轮不进行真实充值、送礼、发送消息或管理提交。Google 商店、首充服务端发货及真实消费仍需独立授权后联调，模拟支付通过不代表真实购买已经验收。

## 本轮结果（2026-11-22）

- 全部 `room_*_test.dart` 与 `app_socket_manager_test.dart`：952 项通过。
- 钱包模型、状态、错误反馈及专用结算测试：11 项通过。
- 最终图片预加载和 theme 导出调整后，首充与礼物面板专项复核 35 项通过，与上述回归重叠，不累计。
- `flutter analyze --no-pub`、`git diff --check HEAD` 均通过；未新增 Flutter Icon 或依赖。
- Android ARM64 Debug APK 构建通过，未安装、重启或改变 Pixel_9 当前会话。
- 初次回归的旧首充跳转断言及旧活动条截图不再符合新规则；修正断言并新建 v4，保留 v3。冷缓存截图曾捕获空图，已在弹层打开前完成真实图片解码，再人工检查新版 320／375 画面并通过截图复核，没有覆盖历史基线。
