# Profile 白卡功能与验收

更新：2026-11-25。范围为 `profile_content_view.dart` 的两张白卡；不扩展下方 Level、Honor 等独立入口。保留已移除 Recharge 的修改及原 VIP/Noble 功能。

> 后续菜单扩展见 [Profile 菜单与设置](profile_menu_flow.md)。本文保留原白卡范围与历史验收记录。

## 入口盘点与结果

| 原入口 | 原问题 | 本次行为 |
| --- | --- | --- |
| Wallet | 已有原生金币充值页 | 保留原流程，返回刷新个人资料；不重新建立内购或余额缓存 |
| Invite Friends | 使用未核实的占位地址 | 使用 Nady `/h5/agent/invite.html`，接通网页桥接、联系人选择、复制和系统分享 |
| Store | 未实现 | 原生商城、7 类装扮、预览、分页、套餐、购买、赠送、余额不足跳转及背包 |
| My Team | 固定假地址 | 仅服务端 position=8 提供有效配置时显示 |
| Agency | 固定假地址、无权限条件 | roleType=1/2/3 且非审核状态时显示 `/h5/agent/index.html` |
| BD | 固定假地址、无权限条件 | isBd=true 且非审核状态时显示 `/h5/bd/index.html` |
| Host | Nady 当前已注释 | 隐藏，不伪造可用功能 |
| Manage | 固定假地址 | 仅服务端有效配置时显示 |
| Daily Reward | 固定假地址 | 原生签到、任务、领奖和任务跳转 |
| Sale Coin | 固定假地址、无权限条件 | 非审核状态，isCoiner=true，或 role=1/3 且 agent/purse/isShow=true |
| Game Coin | 固定假地址 | 仅服务端有效配置时显示 |

动态入口保留服务端顺序，按 ID 去重。无效协议或未支持的原生目标不展示；不把接口失败当成“没有权限”，显示错误和重试。客户端配置与相同账号、环境、角色的并发菜单请求合并。角色字段兼容旧用户缓存，未返回的布尔字段不擅自置为 true。

## 分层与会话

- `profile/tools/`：共享请求、身份校验、入口规则、基础 UI；不是第二套用户/余额缓存。
- `profile/store/`：商城及装扮背包 Model、Repository、ViewModel、View。
- `profile/rewards/`：签到、任务及任务目标解析。
- `profile/binding/`：绑定资料、原手机验证、新手机绑定和本机资料同步。
- `web/web_page_bridge.dart`：H5 协议与导航代次；View 仅渲染、导航和传递操作。
- `ProfileMediaManager`、既有 `RoomShareManager`、`WalletViewModel`：平台能力和内购复用。

所有业务接口统一声明在 HttpApi，通过 HttpDioManager 签名请求。请求绑定 UID/token/登录代次；Dio 发出前再次核对当前账号及页面有效性，防止异步预检后用新账号执行旧操作。关闭页面、切账号、环境或语言改变后，旧结果不回写；H5 跳转后撤销旧弹框的分享/支付能力与回调。

## 商城与背包接口

| 功能 | 方法、接口和参数 |
| --- | --- |
| 新品 | POST `/api/shop/prop/getNewProductFlag`，空 JSON |
| 商品 | POST `/api/shop/prop/getOnSalePropList`，type/pageNum/pageSize=20 |
| 购买/赠送 | POST `/api/shop/prop/purchaseOnSaleProp`，type/id/currencyType/day，可选 targetUserId |
| 赠送查询 | GET 用户主页接口，targetUid；展示服务端返回的真实内部 UID 后确认 |
| 背包 | GET `/api/backpack/prop/list`，type/pageNum |
| 使用/卸下 | POST `/api/backpack/use/goods`，goodsType/goodsId/useState=1/0 |

类别沿用 Nady：头像框3、声波5、气泡2、房间背景6、进场4、座驾8、主页特效7。套餐使用实际 currencyType 和 day；金币1、钻石2分别核对既有 purse。损坏、缺失或非整数价格不按免费处理。

确认购买时固定商品、套餐、价格及真实收礼人；提交前重核收礼人和余额，重复点击合并。网络结果不明不自动重发。业务成功但刷新失败单独提示，不误报购买失败。余额不足返回钱包后只刷新，不自动继续购买。

背包 expireTime 按毫秒解析；duration=-1 或 expireTime=-1 为长期有效。缺失/无效时间不伪装永久有效，过期物品禁止使用。穿戴成功刷新背包和用户资料，原礼物背包不迁移、不替换。

预览复用已有图片/SVGA/VAP/PAG 动效解析和播放器，不进入送礼队列，不调用送礼或占用接口。

## 每日奖励与绑定

签到与任务独立加载，互不覆盖错误。GET `/api/mission/signInfo`、GET `/api/mission/list`；POST `/api/mission/sign` 与 POST `/api/mission/claimReward`（missionId）提交一次。status=1 前往、2领取、3已领取。成功后刷新任务、签到及共享余额；刷新失败期间阻止再次领取已成功的同项，允许用户重试读取。

任务8进入手机号绑定。任务6/7按 Nady 选择自己的房间，携带 Win/Treasure 意图；没有自己的房间则打开创建界面，必须由用户确认创建。普通任务优先当前房间，否则推荐房间/自己的房间。全部复用正常进房、密码和切房确认。请求模式与当前模式不同时，还需原生确认；打开任务本身不切换服务端模式、不开始游戏。

绑定接口：POST `/oauth2/binding/info`；GET `/api/user/hasUser`；POST `/oauth2/sendSms`；POST `/oauth2/verify/code`；POST `/oauth2/replacement/phone`。有绑定手机时先用 purpose=5 验证旧手机，再用 purpose=4 获取新号码验证码。支持 SMS(type=1) 与 WhatsApp(type=2)，120秒发送间隔；修改号码/区号即废弃原验证码状态。首次绑定密码至少6字符并沿用 CryptUtil 加密；换绑不提交新的登录密码。不更换登录会话。绑定完成同步 AuthSession 中手机号/区号及缓存资料，避免后续刷新重新覆盖成旧号码。其他已绑定登录方式只读显示，不另加社交账号绑定 SDK。

## 业务 H5 与桥接

开发/QA 业务 H5 使用 `https://www.simijoy.com`，生产使用 `https://www.simisoul.com`，传当前 language；普通配置网页可以浏览，但只有精确可信源可调用原生/API桥接。保留既有房间网页可信配置，不使用字符串前缀判定域名。

支持 apiCaller、getAppInfo、getUserInfo、changeAppBar、close、closeSmartDialog、openSystemBrowser、jumpNativePage、jumpGamePage、share、commonShare、selectPicture、saveImage、paymentList、paymentCaller。Map 和 JSON 字符串兼容，保留 Nady 回调 `window.nadyBridgeCallback(type,key,jsonString)`。

- commonShare 的聊天/好友选择返回 Nady 的 `{type,data}` 结构；只选人回调，不额外发送 IM 邀请或房间卡片。
- 渠道分享复用系统分享和 Scheme，取消不提示发送成功，不声明实际送达。
- 选图复用已有上传，返回完整图片 URL；保存图片使用 Nady 同款本地插件兼容副本，来源见 `packages/profile_gallery_saver/SOURCE.md`。
- paymentList 结合服务端套餐与 Google 实际可用商品；常规 useType=1、agent=4，首充复用首充 Repository。paymentCaller 不信任 H5 自报金币和价格，匹配有效 SKU 后必须原生确认。继续复用已有 Google 下单、订单校验与回调，不另建充值链路。取消不回调支付成功；只有该次结算的已验证余额更新才能回调成功。
- 原生钱包、商城、背包、VIP、账号绑定及房间目标白名单映射；其他协议安全报错。游戏网页复用既有可信 gameHosts 和房内游戏页，不放宽域名规则。

## UI、图片与插件

沿用 iSnow 浅色主题及原白卡图片；尺寸、颜色、文字样式和 Tab 对比色集中在 `ProfileToolsTheme`。商品、装扮、奖励、动态业务入口图片取自真实接口，缺图使用现有红色缺省图，不拿截图中的示例人物冒充真实用户。没有新增本地业务图片，故无新增 AppAssets 或 assets 目录声明；已有图片继续使用现有常量。本次未新增 Flutter Icon/Icons.*。

相册插件复用 Nady 的 flutter_image_gallery_saver 0.0.2 本地兼容副本，保留 MIT 许可及来源，Android 文件操作放后台线程、API29以下申请旧写入权限；权限 maxSdkVersion 与宿主32统一以避免 manifest 合并冲突。缓存无扩展名图片根据 MIME 处理，MediaStore 写完后发布，复制失败删除未完成记录。其他平台源代码仅随插件保留，本轮不做 iOS 开发或验收。

## 验收记录

- 新增接口、流程、H5、身份、平台通道、布局测试；所有消费、赠送、签到领奖、短信和换绑提交使用替身。
- 320/375/430宽度覆盖长名称、多套餐、错误、小屏和键盘；人工核对后建立 `profile_tools_v1_*` 独立截图，未覆盖历史基线。
- Android ARM64 Debug APK 构建成功；最终检查结果见下方交付记录。
- Pixel_9 已由用户安装并重启；只读验收已开始。设备上仅查看页面、预览、切换和取消，不购买、赠送、领取、发验证码、绑定或开始游戏。
- H5 的真实账号角色、动态配置、Google 商品和服务器写入结果仍需对应环境联调；模拟测试不替代真实后台权限或支付验收。

### 白卡初次实现交付检查（钱包修正前）

- 新增 59 项测试通过（含后续补充的账号切换测试）；与钱包、退出登录回归合计 72 项分次通过，12 张新截图基线通过。
- 扩大回归覆盖 125 个测试文件：1,231 项通过，5 项截图失败。系统消息半屏320/375/430三项在隔离 HEAD 源码复测同样失败，差异分别为6.72%/6.83%/6.76%；未修改其源码或基线。Big Win 375/430两项差异位于底部动态礼物图片帧，当前源码单独复测7项全部通过，HEAD独立复测也通过；保留旧基线，记录为动画帧时序不稳定。
- `flutter analyze --no-pub` 无问题；`git diff --check HEAD` 通过。
- ARM64 Debug 构建通过：`build/app/outputs/flutter-apk/app-debug.apk`，255,221,485字节，SHA-256 `e42940a8bfb336e0d1cbbaaaf2a6c85eb914c17ced01ce037a366488f1670d65`。
- 实现阶段未执行真实购买、赠送、签到领奖、短信、绑定、充值或游戏模式提交；后续用户已自行完成新版安装和重启。

### Pixel_9 只读运行验收（当前可达页面首轮已完成）

- 设备：Pixel_9，emulator-5554，Android API35；应用 com.nady.dev1，versionName=1.0.0、versionCode=1；安装更新时间2026-11-25 16:15:43，运行进程10715。用户已确认安装重启并保留登录。
- 当前日志确认：用户资料、VIP、贵族、体验卡数量查询、position=8 白卡配置、客户端初始化和余额接口均为 HTTP200/code200。客户端初始化 isVersionAuditing=false；未从接口成功推断页面视觉已通过。
- 已读取日志范围内没有 Flutter 未处理异常或布局溢出；未观察到购买、穿戴、签到、领奖、发送验证码、验证码校验、绑定、送礼、VIP/贵族购买请求。此结论仅涵盖已读取的当前进程日志，不代表尚未操作页面的验收结果。
- 自动操作限制：Android Studio 的 Running Devices 窗口为空，Computer Use 无法识别独立 Pixel_9 窗口。已尝试展示现有镜像，没有重启/重装设备，没有改网络、账号、房间或权限。
- 用户截图确认：第一卡为 Wallet、Invite friends、Store；第二卡为 Daily Reward、Game coin、Treasure Hunter、Sweet House、庄园、Telegram Channel、WhatsApp Channel。实际可见入口已通过；这不代表其内部页面已经验收。
- 调试服务只读检查的当前用户数据：UID30317291，roleType=0、isBd=false、isCoiner=false；旧缓存的可选字段为空。Agency/BD/Sale Coin 隐藏符合当前角色，未通过修改账号或伪造权限验证。
- 已请用户接手商城7分类、预览/套餐显示、余额及背包只读查看；之后再检查 Daily Reward、绑定页面及邀请H5。未点击购买、赠送、使用/卸下、签到、领奖或验证码操作，未查看的项目仍标待验收。

#### 商城与装扮背包：首轮浏览验收通过

- 用户确认 Store 的7个分类、商品图片/动效预览、套餐价格及余额显示正常，Dress-up Backpack 查看正常。
- 当前进程日志核对：商城 type=3/5/2/6/4/8/7 的 pageNum=1、pageSize=20 请求均返回 HTTP200/code200；背包7类查询成功，进场装扮 pageNum=2 请求也成功。未据此宣称所有分类的后续分页或真实购买/赠送已完成验收。
- 无 Flutter 未处理异常/布局溢出；未观察到商城购买/赠送请求。
- 例外操作：设备时间16:22:28手动卸下进场装扮 goodsId=74（goodsType=4、useState=0），16:22:30服务器返回 HTTP200/code200，traceId=e938296e-0099-47b9-be07-a6f4a9eb81ee。用户已明确确认是其点击 Remove，代理没有执行这笔操作，未自行重新穿戴。此次记录不能写成“完全没有账户提交”，也不归为自动触发缺陷。
- 下一步：Daily Reward 的只读展示，以及存在可用绑定任务时仅打开绑定页面；不签到/领奖/发码/绑定，不执行游戏任务。

#### Daily Reward：页面打开与数据加载通过

- 用户确认 Daily Reward 正常打开。当前进程的签到与任务查询均返回 HTTP200/code200；已读取日志内没有签到、领奖、发码、校验验证码或绑定请求，也无 Flutter 未处理异常/布局溢出。
- 调试服务只读核对：签到连续天数0；当前任务仅 id=5“Follow a new friend”和 id=4“Send Gifts in the room”，均 status=1、progress=0、total=1。用户没有获准通过执行任务来改变此状态。
- 当前任务列表无id=8手机号绑定任务；源码可达入口为该任务和可信H5原生跳转，没有为验收添加新入口或伪造任务。因此绑定页当前账号无法通过每日任务访问，保留待验证，不能写为视觉验收通过。
- 页面打开正常由用户确认；键盘、绑定显示、签到/领奖真实写入等不在这次已通过范围。邀请H5和钱包随后完成检查，结果见后续小节。

#### Invite friends 与 Wallet：打开通过，钱包套餐发现异常

- 用户确认 Invite friends 和 Wallet 均正常打开。邀请网页的 info、rewardMsg、inviterIncome、weekly-invite-rewards 查询均返回 HTTP200/code200，表明网页的查询桥接链路已实际工作；未进行邀请、分享或奖励领取。
- 余额查询成功，日志中金币49,855,108、钻石35,338保持不变。钱包“页面打开正常”不能替代“套餐列表成功”：17:07:45套餐接口 queryByChannel 返回code1002、msg“不能为空”，traceId=613847cf-c75d-490d-a834-b2081ce37a6c，故套餐列表仍待复测。
- 与Nady源码对照：api_client.dart 的 queryRechargeByChannel 使用 POST、@Query(channel/merchant)；生成代码 api_client.g.dart 的_data=null。iSnow此前额外传了空JSON对象。本轮已移除此请求体，保持google/google查询参数，不修改签名、下单或支付规则；后续同账号真实查询已返回code200，修正有效，证据见下方复测记录。
- 新增钱包请求适配器测试3项，验证无请求体、查询参数、签名、列表排序及服务端msg；相关钱包/网页测试共21项通过，静态分析与差异检查通过。源码已由IDE热重载，调试服务确认WalletRepository新增字段已加载，App未重启。
- 已请用户仅重开/刷新Wallet核对套餐卡片，后续真实响应已成功，结论更新为套餐查询复测通过。当前安装APK仍是此前构建版本，此修正先以热重载加载。
- 模拟器同时提示Google Billing API不可用；属于支付环境限制，不将钱包网页或查询成功等同于Google真实支付通过。本轮无下单、充值、签到/领奖或绑定操作；用户此前手动Remove的例外保持单独记录。

#### Wallet 修正后真实接口复测：通过

- 用户重开Wallet后确认余额和充值套餐卡片均正常显示。
- 设备时间18:20:21，queryByChannel查询返回HTTP200/code200、message=success，traceId=6a4e24d0-a116-4d86-ad88-4f2a225e81df；此前额外发送空JSON时为code1002。按Nady保留POST查询参数并移除JSON请求体后，同账号运行复测成功。
- 同次余额：金币49,855,108、钻石35,338。读取的本次日志没有下单、支付、签到/领奖、绑定、穿戴、送礼提交或Flutter未处理异常。历史手动Remove操作仍按前文单独记录，不能据滚动日志未包含它而抹去。
- 已完成的可达页面：白卡实际入口、Store7类/预览/套餐与余额、装扮背包、Daily Reward打开和数据、Invite friends打开及查询桥接、Wallet余额与套餐。视觉由用户确认，接口与运行状态由代理核对。
- 仍待条件：手机号绑定页（当前无id8任务入口）、Agency/BD/Sale Coin（当前普通账号无权限）、动态活动/渠道入口的外部跳转；真实购买、赠送、签到/领奖、验证码、换绑及Google支付均未在本轮执行。模拟器支付环境限制不因套餐加载成功而解除。
- 当前运行App通过热重载加载修正，没有再次重装或重启；包含钱包修正的ARM64 Debug APK重新构建成功：`build/app/outputs/flutter-apk/app-debug.apk`，255,209,836字节，SHA-256 `a28facee8744fb640d733a62a4d1f7abebc67bade435b18bccaf8494e70e653a`。这是当前最新构建，前文e42940…为修正前版本。无需为本轮复测再次安装。
