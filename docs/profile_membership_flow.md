# Profile VIP / Noble 会员流程

## 范围与入口

首页 VIP / 贵族双卡保留并排布局，背景、徽章与文字分层渲染，停止使用含固定“已开通 10 天”的整张 VIP 图。卡片状态来自会员接口，区分加载、未知、未开通、已到期、剩余时长和长期有效；接口失败不据此宣称用户没有会员。

路由：`/vip`、`/vip/settings`、`/vip/history`、`/noble`、`/noble/history`、`/noble/titles`。`/vip?level=3` 用于设置页定位所需权益等级。等级切换与主卡滑动共用选中状态，横向等级栏将选中项保持在可见区域。

VIP 展示实际等级、经验、有效期、权益预览和服务器套餐。贵族按接口等级展示背景、权益、折扣套餐和有效期；未启用或无有效套餐时禁止购买。详情页布局和图片参考 Nady，字体使用 iSnow 现有字体。

## MVVM 与会话

代码位于 `lib/classes/profile/membership/`：View 渲染与导航；主 ViewModel 负责等级、套餐及提交流程；辅助 ViewModel 负责设置、记录、奖励及称号；收礼人 ViewModel 负责独立搜索状态；Repository 封装 HTTP、响应映射与用户同步。

接口路径全部通过 `HttpApi`，请求统一走 `HttpDioManager`。会员主数据在内存中按 API 环境、语言、UID、token 与登录代次隔离，同键请求合并；主动刷新及提交成功使缓存失效。等级数据不建立第二套持久化缓存。`UserData.userLevel` 为可选类型化字段，旧缓存缺字段仍可正常读取；保存用户时保留该字段。

主页并行获取 VIP 和 Noble。两个来源各自加载、报错，互不阻塞。VIP 体验卡数量属于辅助请求，其失败不隐藏 VIP 主页面。切账号、退出登录或重新登录产生新会话；旧请求不得写回新会话。没有订阅页面时暂停倒计时，恢复订阅后继续按当前时间计算，销毁时释放计时器。

## 接口协议

| 功能 | 方法、路径及参数 |
| --- | --- |
| VIP 信息 | `GET /api/vip` |
| VIP 开通、续期、赠送 | `POST /api/vip/buy`，`{gradeId, targetUid}`；给自己开通时保留 `targetUid: null` |
| 体验卡数量、赠送 | `GET /api/vip/giveExperienceCard`；POST 同路径 `{targetUid}` |
| VIP 设置 | `GET /api/vip/setting?uid=内部UID`；POST `{id, open}` |
| 封禁查询 | `GET /api/vip/block?userNo=展示ID` |
| 解除封禁 | `GET /api/vip/unblock?targetUid=内部UID`；该 GET 是有副作用的操作，必须确认，不自动重试 |
| 贵族信息 | `GET /api/aristocracy` |
| 贵族购买、续期、升级、赠送 | `POST /api/aristocracy/buy`，`{aristocracyId, gradeId, targetUid}` |
| 奖励额度、赠送 | `GET /api/aristocracy/giveInfo`；`POST /api/aristocracy/give`，`{aristocracyId, targetUid}` |
| 称号列表、领取或替换 | `GET /api/aristocracy/plaque`；`POST /api/aristocracy/get`，`{id}` |
| VIP 历史 | `GET /api/vip/history`，`{pageNum, pagePage: 20}`，沿用 Nady 的参数拼写 |
| 贵族历史 | `GET /api/aristocracy/history`，`{pageNum, pageSize: 20}` |
| 收礼人查询 | `GET /api/user/homepage/get?targetUid=输入值`，沿用 Nady；提交始终使用返回的 `userBaseInfo.uid` |

VIP 浏览不同等级仅切换权益预览，购买请求不传所浏览的等级；实际升级由服务端经验决定。价格与天数使用服务端套餐，贵族优先展示有效折扣价；缺价格、无效 ID 或无效天数的套餐不可购买。

VIP `endTime` 为毫秒；贵族 `userInfo.remainTime` 沿用 Nady，实际是秒单位的到期时间戳。倒计时不小于零；到期时只触发一次重新查询，避免服务端状态暂未更新导致循环请求。

## 操作规则

- 购买、赠送、解除封禁先确认费用、对象与套餐；确认固定当前套餐及返回的内部 UID。提交中防重复点击，变更搜索输入立即清除旧对象，迟到搜索结果不生效。
- VIP4 及以上且会员有效、有剩余卡时可赠体验卡；收礼人必须为正常、未封禁且没有 VIP 的用户。
- VIP6 且会员有效才提供解除封禁入口；目标状态必须为封禁，费用来自查询接口，正常账号不能执行。
- 贵族不能向自己或收礼人购买低于其当前等级的贵族。未启用等级不可购买。
- 贵族奖励入口沿用 Nady：自身等级及当前所选等级均至少为5；按 `limitCount - sendCount` 校验可赠数量。
- 称号需要帝王等级，已被他人领取的称号不提交。已有称号时明确确认替换；占用冲突等服务端错误优先显示 `msg`。
- VIP 设置只展示 Nady 当前启用的隐身进房、隐身访问两项；等级不足定位到对应 VIP 等级。勿扰项保持隐藏。保存失败保留原值，保存中禁用对应操作。
- 历史记录支持刷新、分页、去重及失败重试；刷新从第一页开始。

金币不足时允许打开已有 Wallet，返回只刷新，不自动重新购买。充值仍使用现有内购模块，本功能不新增会员内购插件。

## 提交结果、资源和生命周期

业务错误优先显示服务端 `msg`；无可用文案时使用当前语言兜底。购买超时或结果不明确时只查询状态，不自动再次扣费。成功后刷新会员、用户持久化信息、余额和受影响的辅助列表；用户刷新与余额刷新独立执行。刷新失败展示“操作成功，部分信息刷新失败”，不能显示为购买失败。

`accountBalanceRevisionProvider` 是失效通知，不存储第二份余额；Wallet 只刷新余额，不重启内购；礼物面板复用已有带账号代次与余额版本保护的查询和缓存更新。

权益及成功动效复用现有 CDN 缓存和 SVGA/VAP/视频播放器，不进入房间礼物队列，不调用房间音乐或 Agora。动画下载失败不改变业务结果，成功层仍可手动关闭。页面拥有的底部面板、确认框和动效层在页面销毁或账号会话切换时关闭；不关闭其他模块的路由。

静态图片来自 `/Users/huili/nady/assets/images/`，仅复制实际使用的32张资源至 `assets/lanhu/profile/membership/`，来源及 SHA-256 记录在该目录的 `manifest.json`。首页还复用原有双卡图片中的皇冠、星形区域，只在 UI 中裁切展示图案，不显示烘焙进图片的过期推广文案，不改动原图片文件。所有资源经 `AppAssets` 引用，视觉 token 在 `lib/theme/membership_theme.dart`，缺失图片使用全局红色占位图。禁止 Flutter `Icon/Icons.*`。

## 验证记录（2026-11-03）

- 首轮接口/业务36项、页面13项通过；覆盖扣费请求参数、空成功响应、`msg`、缓存、账号代次、重复点击、超时不重发、有效期单位、旧缓存、权限、额度、设置回滚、分页、赠送确认和弹层关闭。
- 已人工检查320/375/430宽度的 VIP/Noble 截图，修复贵族主卡收窄与选中等级未保持可见的问题；小屏允许内容滚动，操作栏保持可见。
- 新基线独立命名 `profile_membership_v1_*`，不覆盖历史房间、Share、音乐或消息基线。
- 最终全项目回归852项全部通过；会员接口/状态36项、页面13项包含在内。`flutter analyze --no-pub` 无问题，`git diff --check HEAD` 通过。
- 回归中发现原有登录页测试默认期待 `+996`，而 HEAD 中登录页早已默认沙特 `+966`。将该选择器测试改为显式传入 `KG/996` 后通过；未修改登录页产品逻辑或任何历史截图基线。
- Release 构建通过：`flutter build apk --release -t lib/lib_dev.dart --no-pub`。输出 `build/app/outputs/flutter-apk/app-release.apk`，336,528,222字节，包名 `com.nady.dev1`，版本 `1.0.0+1`，APK v2签名校验通过。
- APK SHA-256：`1e31b35856ee4283d1203adb936f6afa07027d73571b0c1b9fa491e01a59ddd2`。
- 当前 ADB 未检测到 Android 设备，未进行真机热重载、真实 CDN 动效或支付链路验收。Android/iOS 真机结果均未验证。
- 所有扣费、赠送、领取、解除封禁测试均使用接口替身，未进行真实账户操作。

## 维护边界

本次仅整理 Profile 的会员区域及新增模块的 theme token。原 Profile 其他区域仍有历史裸视觉值，本次没有扩展为全页重构。此前移除 Recharge 的菜单及点击分支继续保留。
