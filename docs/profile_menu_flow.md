# Profile 菜单、Honor、完整背包与设置

更新：2026-11-25。此文承接 [白卡功能记录](profile_tools_flow.md)，本轮覆盖 `_ProfileMenuRow` 的七项入口；保留 Recharge 已移除、商城/VIP/Noble 与白卡历史验收结果。业务参考本地 Nady，UI 使用 iSnow 浅色主题和当前字体。不引入插件。

## 入口与行为

| 入口 | 当前实现 |
| --- | --- |
| Level | 现有 WebView 打开 `/h5/userlevel/index.html?language=…`；开发/测试域名 `www.simijoy.com`，生产 `www.simisoul.com`。入口传 `hiddenAppBar=true`，仅展示 H5 自带导航与返回，沿用网页桥接、加载失败重试及关闭按钮；协议等页面保留原生导航。 |
| Backpack | `/backpack` 默认 Gifts，另外七项为现有 Avatar frame / Sound wave / Chat bubble / Room background / Entry effect / Vehicle / Profile effect。Store 的 `/store/backpack` 默认 Avatar frame。 |
| Honor | `/honor`，ExtendedTabBar/View 的 Achievement / Gifts / Special；真实阶段、拥有状态、描述、获得/到期时间与静态/动画预览。 |
| Settings | 账号安全、VIP Settings、服务端黑名单、语言、协议、About、注销/登出；内容可滚动，无开发调试选项。 |
| About Us | iSnow、已有项目 Logo、真实 PackageInfo 版本/构建号、手动更新和协议。移除旧日记文案与邮箱。 |
| Privacy / Terms | 集中在 ProfileToolsConfig，分别使用 `https://www.simisoul.com/policy.html` 与 `/protocol.html`；旧 Settings 路由也复用新页面，不再引用 example.com。 |

可信 H5 的 `me-backpack`、`me-badge` 和 `me-set-account-security` 也指向对应完整原生页面。

## Honor 状态与契约

2026-11-26：修正 Level 重复导航栏。隐藏状态在打开时初始化，热重载后需关闭并重新进入 Level；不需要重启 App，不额外添加顶部占位，继续由既有桥接传递状态栏高度。

本次导航修复的菜单/网页桥接相关测试26项通过，静态分析及差异检查通过。Pixel_9 已通过现有 IDE 调试会话热重载（1个库），未重启/重装 App；设备镜像暂不能操作，重新进入 Level 后的单导航显示、状态栏避让及两种返回行为待用户画面确认，不能记为设备验收通过。

| 方法 | 接口 | 参数 / 结果 |
| --- | --- | --- |
| GET | `/api/medal/showList` | `type=1/2/3`，解析 Badge、MedalStage |
| GET | `/api/medal/achieved` | `targetUid` 为内部 UID；共享仓库合并同账号并发请求，首页显示 Honor 数量，失败不伪装为 0 |
| GET | `/api/medal/wearingNum` | `{wearingNum}`，异常不假定上限 |
| POST | `/api/medal/wear` | `{medalIds: [有序字符串 ID]}` |

- 佩戴来自真实 `userWearMedalVOS`，UserData 新增可选类型化字段，旧缓存兼容；保存成功沿用共享用户刷新，更新持久化资料/余额修订，返回首页刷新资料与数量。
- 最终数量为服务端上限与 Nady 贵族上限的较小值：普通3、贵族4级6、5级8、6级10。读取失败禁用编辑/保存并提供重试。
- 编辑只展示已拥有勋章；点击勋章添加/移除，点击已佩戴项移除，长按已佩戴项拖动排序。取消/首次返回只退出编辑，不请求保存。
- 保存重新查询账号、贵族等级、上限和全部分类，拒绝无效、过期、未拥有、重复或超限 ID。失败保留草稿。成功与后续刷新失败分别反馈，不自动重复提交。
- 多阶段预览使用独立 StorePreview/现有动画播放器，不入房间送礼队列；关闭预览释放控制器及资源。

Nady 依据：`pages/main/sub_pages/me/badge/provider/badge_provider.dart`、`badge/model/badge_model.dart`、`services/api/user_api.dart:631` 起，`services/http/api_client.dart:1100` 起。

## 完整背包与转赠

- Gifts 分别 GET `/api/backpack/list` 和 `/api/backpack/user-prop/list`，后者固定为 type9；不误用房间 `/api/gift/info/getBackpack`。按来源/itemType/ID 区分，显示真实数量、最近到期时间，点击预览。无独立离房发送按钮，与 Nady 此页一致。
- 七类装扮沿用现有查询、分页、穿戴/卸下、有效期、静态与动画预览。VIP 状态独立加载；失败显示重试，不能冒充非 VIP。
- VIP≥5 显示转赠。复用收礼人查询/选择，清空输入即废弃旧选择。禁止自己、封禁/异常账号、无效或过期装扮。
- 确认显示具体装扮、收礼人昵称和内部 UID。提交前复核当前 VIP、账号、收礼人及库存实例，POST `/api/backpack/send/goods` 为 `{targetUid, id}`，`id` 是背包实例 ID，绝非 goodsId；不调用商城购买。
- 转赠期间锁定选择和重复入口，取消无写入。超时/结果不明不自动重试。成功刷新库存与用户，刷新失败提示“操作完成但资料刷新失败”。

Nady 依据：`pages/main/sub_pages/me/nady_me_backpack_page.dart`、`nady_me_backpack_provider.dart`；`services/api/user_api.dart:330-362,815`。

## 设置、黑名单与更新

- 账号安全 POST `/oauth2/binding/info`，展示手机号项及已绑定社交项；社交项只读，手机号进入已有 `/account-binding`。打开页面不发验证码；绑定、变更密码/手机号沿用旧实现，不另建链路。
- VIP Settings 复用现有 `/vip/settings`；不复制第二套开关状态。
- 黑名单 POST `/api/user/blacklist/list` 为 `{pageNum,pageSize:20}`，解析 `list[].targetUserInfo`，按内部 UID 去重；加载、空、失败、重试、刷新/更多独立处理。点击用户打开原个人主页。
- 确认后 POST `/api/user/blacklist/update` 为 `{targetUid,blackOrNot:false}`。失败保留原列表，成功移除并重新查询。旧 Isar blockedUsers 数据原样保留，不合并、不删除或自动迁移。
- 注销/登出保留现有 ProfileViewModel → LoginProvider 房间清理和二次确认；共用确认入口，旧账号的确认不能注销新会话。真实操作不在本轮设备验收范围。
- About 首次只读 PackageInfo，不自动查版本；用户点击检查才 POST `/api/app/version/get`，请求体包含真实包版本/构建号、应用名、当前应用/系统语言、设备信息、渠道等 Nady 公参。
- 更新响应类型化为 needUpdate/updateType/title/explain/skipUrl，失败不显示“最新”。有更新显示说明，仅用户点击打开有效 HTTP(S) 链接；不下载、安装、不加入启动强制升级。无有效链接明确提示。
- 服务端错误优先 msg。Repository 统一走 HttpApi/HttpDioManager；View 不访问鉴权、网络或数据库。账号/环境切换重建状态，页面关闭后的旧请求不能提交或更新 UI。根弹层随所属页面/账号失效关闭。

Nady 依据：`pages/settings/nady_setting_account_security*.dart`、`model/me/me_model.dart:52` 起，`services/api/user_api.dart:228-245`，`services/api/common_api.dart:80`，`model/common/version_model.dart`。

## 资源与验收

- 视觉参数在 ProfileToolsTheme/AppAssets，复用已有图片，无新增 Flutter Icon/Icons，无社交 SDK/其他插件。
- [资源复用清单](../assets/lanhu/profile/menu_manifest.json)记录图片实际路径、来源与哈希；勋章/礼物图来自接口，缺图用红色占位。未用固定示例勋章或等级替代用户数据。
- 新版菜单截图位于 `test/goldens/profile_menu_v1/`；新增 Gifts 后的装扮背包基线独立命名为 `profile_tools_v2_backpack_*`。原 v1 背包、商城、签到、绑定、会员和房间历史基线保持不变。
- 自动化覆盖：API 方法/参数、旧缓存、时长/日期、多语言、勋章编辑取消/排序/上限/失败、转赠前置校验与防重复、黑名单分页/失败、账号切换、更新错误/链接/取消、七个菜单路由，以及320/375/430布局和无提交的确认取消。
- Pixel_9 本轮新菜单尚未完成设备验收。不得将模拟测试或旧白卡验收当作新菜单真机结果。后续仅浏览/预览/取消；不真实穿戴/转赠、解除拉黑、发验证码/绑定、领取、消费、注销或登出。

### 2026-11-25 自动化结果

- 本轮最终相关测试（菜单、Honor、背包、设置、白卡、H5、退出生命周期）103项通过；Big Win 独立回归7项通过，共110项通过。
- 全量 `flutter test --no-pub`：1468项通过、5项截图失败，与此前记录的三项系统消息半屏及两项 Big Win 动画帧差异一致。Big Win 在单独复测中7项均通过；系统消息三项为先前已核对的历史基线问题，本轮未修改相关代码或基线。全量结果不能写为全绿。
- `flutter analyze --no-pub` 无问题；`git diff --check HEAD` 与新增源码空白检查通过。
- Android ARM64 debug 构建成功，入口 `lib/lib_dev.dart`，产物 `build/app/outputs/flutter-apk/app-debug.apk`。未覆盖安装、重启或更改 Pixel_9 登录/房间。
- 设备只读确认：Pixel_9 的现有 iSnow 进程仍在运行。新 `/honor`、`/backpack` 与账号安全路由需重新初始化路由表；按此前不自动重启约定，设备验收待确认热重启方式，不能声称已通过。
