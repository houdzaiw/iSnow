# 房间送礼、全屏动效设计与资源映射

> 检查日期：2026-11-14（Asia/Shanghai）
>
> iSnow源码基准：`caaecab2b9d326b617566a3636dd16b822393a8e`
>
> 配套文档：[功能缺口盘点][audit]。功能编号G/E/R及待确认编号D均来自该文档。
>
> 本文保留来源核对结果，并同步第一批接入状态；功能实施进度见配套盘点第8节。

## 1. 来源选择规则

- 功能逻辑采用[飞书记录][feishu]，不以静态稿中的样例数字推导接口行为。
- UI优先采用用户指定的[蓝湖项目][lanhu]；未定位到独立设计稿的部分，用户已明确授权参考Nady。
- 动效图标先从[房间动效文件][asset-root]查找，不足部分参考[Nady本地动画目录][nady-animation-root]。存在候选文件不等于已接入或真机验证。
- 真实头像、昵称、礼物、价格、角标、等级和奖池金额由接口/Socket提供。设计样例人物、礼物和固定数量不能成为业务默认数据。
- 后续接入仍遵守[房间资源规范][asset-policy]和[主题规范][theme-policy]：视觉参数集中在theme，资源经AppAssets引用；房间内不使用Flutter `Icon/Icons.*`，确无资源时保留红色缺省图并记录原因。

## 2. 蓝湖设计对应

项目ID为 `9ab318f9-4876-4218-a940-73d4c98780c2`，团队ID为 `7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6`。本轮接口返回312张设计；核对下列6张相关稿的原始图层。接口列表显示的尺寸存在缩放，以下采用原始画板坐标：主体375×812，素材页132×812。

| 编号／对应功能 | 设计名称与image_id | 已核实的图层／状态 | 使用边界 |
| --- | --- | --- | --- |
| L01：G01/G06/G15，礼物主面板 | [直播间-礼物][lh-gift-main]；`dd85e4a7-00f5-41c9-a75b-b28a25da69ad` | `bg`、`礼物`、`栏目`、`all on mic`、`座位`、`钱包&send`、`进度条`；目标文字All On Mic，两行四列礼物。 | 既有礼物面板主依据。原始稿面板背景从y=451起；First Recharge及活动条在面板上沿，不用截图替代可交互控件。 |
| L02：G07/G09，未选目标状态 | [直播间-礼物][lh-gift-none]；`714de4f4-6a54-4b2f-a3a0-14c3ad91167f` | 与主稿相同的礼物、分类、钱包结构，目标区出现None。 | 用于未选目标视觉对照；不根据None示例取消现有麦下定向及多选能力。 |
| L03：G01，网格未展示的状态稿 | [直播间-礼物][lh-gift-empty]；`9bd2450c-0a47-448c-a450-936428413346` | 保留分类、目标、钱包；礼物区域未列出Gift name，存在100×100的`Frame`导出。 | 稿中未明确标注这是加载、空数据或异常；不能仅凭没有礼物推断业务含义。具体状态继续采用现有加载/空/失败模型，待必要时核对该Frame内容。 |
| L04：G06/G07，目标和数量展开 | [直播间-礼物][lh-gift-expanded]；`cb3f0c2a-91aa-4ed7-b5cc-e2a6c2ada4d6` | All Room/Select/All on Mic；`送礼数量`图层ID `15274:376991`，画板坐标185,632，尺寸122×124；包含200/666/888/8888等示例选项。 | 展示下拉位置和样式；实际选项仍由配置提供，自定义上限采用功能需求，不能硬编码稿中数字。 |
| L05：G10/E09/E10，跑道和连击 | [送礼鎏光][lh-gift-flow]；`e459e31d-0447-43c5-81c8-5b4be084307e` | `Component 565`/`Component 566`约226×50；`Group 1312318940`/`Group 1312318941`含中奖数字；`Frame 1312319489`位于21,669，尺寸106×106，为连击组合。 | 昵称、x20、win及13.5K是示例；需要真实文本、累计量和动态计数，不能下载数字切图冒充真实状态。 |
| L06：E12，麦位装饰参考 | [直播间-素材][lh-room-materials]；`4a6d40ff-2e2b-4d9d-b6d1-dff21fe18895` | `头像框`、`老虎 2`、`Component 400/401`及关注图层；132×812素材画板。 | 只用于装饰比例和叠层参考；示例头像框不等于当前用户拥有。麦浪/头像框/临时层仍由真实数据决定。 |

既有公屏位置与挂件避让继续参考[直播间-15麦位][lh-room-chat]（`cc03dc0c-a1e5-4dcc-ba8f-6bb2cfd909d2`）及[公屏布局记录][chat-ui]；它不是23档数字、SUPER或全屏关闭按钮的独立效果稿。

### 2.1 已有切图提取能力

[下载脚本][asset-script]已支持HTML的img、行内CSS及background/background-image，并针对主礼物稿建立语义映射：

| 原始区块／图层 | 现有资源文件 | 说明 |
| --- | --- | --- |
| `bg / Frame_1312319043`、`水果-土耳其_1` | `room_gift_first_recharge.png`、`room_gift_campaign.png` | 静态入口底图，不能代替真实返奖轮播。 |
| `钱包&send / 300x300-金币_1`、`Vector_8467`、`Polygon_25` | `room_gift_coin.png`、`room_gift_balance_arrow.png`、`room_gift_count_arrow.png` | 金币及箭头；实际金额和数量使用文字/控件。 |
| `栏目 / 背包`、`all on mic / Polygon_25`、`座位 / ic_room_micsize` | `room_gift_backpack.png`、`room_gift_target_arrow.png`、`room_gift_recipient.png` | 分类和收礼人区域。 |
| `礼物 / Frame_1312319194` | `room_gift_new_badge.png` | 仅在接口明确提供对应角标时显示，不伪造CP/VIP等身份。 |

图层名称只在对应image_id内有效；后续还需新增导出时继续扩展现有脚本。上述文件的现有声明可核对[AppAssets][app-assets]和[蓝湖资源manifest][lanhu-manifest]，本轮未重新下载。

## 3. 未定位独立蓝湖稿的Nady参考

“参考”表示已找到相关源码或文件，不代表Nady旧实现自动满足较新的飞书排队及抢占规则。

| 对应功能 | 已找到的Nady参考 | 应如何使用／尚缺什么 |
| --- | --- | --- |
| G12，普通礼物面板预览 | [NadyRoomGiftWidget][nady-gift-player]及[礼物面板][nady-gift-panel] | 可参考格式分流和播放结束处理；本轮未定位到与本地PRD完全相同的普通礼物预览窗。Nady的 `showJackpotPreview` 是SUPER预览，不等于所有礼物预览。布局按现有蓝湖风格适配，仍需D05的槽位和生命周期验收。 |
| G13/G14，幸运轮播及SUPER | [jackpot_panel_banner.dart][nady-jackpot-panel]、[jackpot_rolling_number.dart][nady-jackpot-number]、[gift_panel_widget.dart][nady-gift-panel] | 已有选中礼物返奖快照、SUPER/普通模式、金额滚动及单面板预览去重参考。查询沿用 `/api/gift/info/lucky/banner-snapshots` 的giftId/type=1/pageNum=1/pageSize=3；在iSnow实施时需通过HttpApi/Repository接入。 |
| E04，23档数字 | [nady_room_lucky_num_layer.dart][nady-lucky-num] | 有按累计数量判档、最高命中档和对应素材播放参考。其旧队列不直接覆盖飞书规定的全屏/数字互斥。 |
| E05，三档中奖气泡 | [nady_room_lucky_layer.dart][nady-lucky-bubble] | 有 `gift_award_bubble_config` 配置读取及倍率素材处理；本地文档 `awardBubbleConfig` 是业务配置概念，实际配置ID/返回结构需按Nady和后端核实。 |
| E01/E17/E18，全屏播放与关闭 | [nady_room_gift_layer.dart][nady-gift-layer]、[nady_room_gift_widget.dart][nady-gift-player] | 可参考现有播放器分流；本轮查看的这两个文件未提供完全同款的独立关闭控制器。独立关闭/提前释放是飞书要求，需另接安全区图片按钮；Nady的[关闭图片][nady-close-icon]可作候选，不能据此声称关闭流程已存在。 |
| E09/E10，礼物跑道 | [gift_flowing_v2/nady_gift_flowing_widget.dart][nady-gift-track]及同目录队列/入数动画 | 参考头像、累计数量及中奖增量展示；本人插入后B回队保留时长必须按飞书实现，不能照搬丢弃逻辑。 |
| E11，进场与座驾 | [nady_enter_room_animation.dart][nady-entrance]、[nady_room_vehicle_layer.dart][nady-vehicle] | 对应进场条及座驾联动的视觉/素材参考；起播30秒预算、本人优先需按飞书补齐。 |
| E08，动态降级技术参考 | [nady_gift_degrade_policy.dart][nady-degrade]、[nady_fps_monitor.dart][nady-fps] | 源码含FPS阈值24/16/12、10秒窗口、1秒通知，也有CPU及四档扩展。只记录为候选，不能默认等同于飞书full/reduced/minimum三档；D01仍需验证映射与恢复。 |

### 3.1 Nady动画文件候选

以下文件均已核对存在于[本地Nady动画目录][nady-animation-root]；本批未新增复制这些Nady重动画，未验收所有素材的透明模式、音轨和动态槽位。

| 资源组 | 文件及完整性 | iSnow当前状态／使用边界 |
| --- | --- | --- |
| 连击数字 | `luck_num{n}.mp4`；n为10、20、30、50、66、88、100、200、300、400、500、1000、2000、5000、5555、6000、6666、7000、7777、8000、8888、9000、10000，**23个文件全部存在**。 | 2026-11-16已接入23档策略与数字通道，真实`text`槽位替换昵称；全部文件为VAP，不按不透明MP4播放。 |
| 中奖气泡 | `luck_win_small.mp4`、`luck_win_medium.mp4`、`luck_win_big.mp4` | iSnow只打包小档；配置、三档分流及动态内容待接入。 |
| 全房散开 | `all_room_gift_effect.svga`（37,255字节） | iSnow当前使用原生径向图片散开；SVGA礼物图片槽位需核对，不能直接互换表现。 |
| SUPER面板 | `jackpot_gift_panel_anim.mp4`（188,391字节）及Nady图片目录的 `jackpot_gift_panel_bg.webp`、`jackpot_digital_0..9.webp` | 面板动画/背景/金额属于同一展示功能，不使用整张海报替代动态金额。 |
| Jackpot全屏 | `jackpot_full_screen_anim.mp4`（913,507字节） | 同名文件已在iSnow的assets/room_gift中；仍缺统一排队及专项抢占。 |
| 连击按钮 | `combo_button_animation.pag`（55,571字节）、`jackpot_combo_button_anim.pag`（15,036字节），另有 `combo_effect.pag`、`jackpot_combo_effect.pag` | iSnow已打包普通combo背景；不能将播放背景等同于已实现点击累计、震动及防抖。 |
| 火箭等级素材 | `big_rocket_fly_lv1..6.mp4`及Nady图片目录相关VAP/PAG | 文件候选可查；需要与真实引爆事件等级、飘屏及全屏联动映射，不能用Rocket状态事件代替奖品事件。 |

iSnow现有[动效manifest][gift-manifest]只列普通combo、Jackpot全屏和小档中奖3份资源；[AppAssets][app-assets]中的礼物ID本地动画映射当前为空。此事实只描述已打包资源，不表示服务端礼物的animationUrl不能播放。

## 4. 用户提供的本地WebP清单

目录共37个可见文件：**22个动态WebP文件，另15个PNG/JPG定位或静态参考文件**。以下宽高及帧数来自RIFF/VP8X/ANMF元数据，单位px；不是Flutter播放验收。哈希对比在iSnow的assets目录内进行，“未匹配”仅表示未发现字节完全相同的文件，不据此断言相应功能完全缺失。

| 编号 | 原始文件 | 尺寸 | 帧数 | 使用位置／关联 | 本次接入核对 |
| --- | --- | --- | --- | --- | --- |
| A01 | [直播间送礼按钮动效/直播间送礼.webp](</Users/huili/Downloads/房间动效文件/直播间送礼按钮动效/直播间送礼.webp>) | 176×176 | 10 | 房间底栏礼物入口；按钮位置参考图已查看。 | 第一批已原样复制为 `room_gift_button_animation.webp`，由[底栏按钮][current-gift-button]引用 `AppAssets.roomGiftButtonAnimation`。 |
| A02 | [直播间-个人卡片-送礼按钮/直播间-个人卡片-送礼按钮.webp](</Users/huili/Downloads/房间动效文件/直播间-个人卡片-送礼按钮/直播间-个人卡片-送礼按钮.webp>) | 84×84 | 10 | 房内用户卡Send Gift按钮内的小礼物；位置参考图已查看。 | 第一批已原样复制为 `room_member_gift_animation.webp`，由[用户卡按钮][current-member-gift]引用 `AppAssets.roomMemberGiftAnimation`。 |
| A03 | [bigwin游戏贴脸横幅/游戏贴脸横幅.webp](</Users/huili/Downloads/房间动效文件/bigwin游戏贴脸横幅/游戏贴脸横幅.webp>) | 375×55 | 16 | **游戏面板顶部邀请横幅**，位于游戏内容上沿；位置图已查看。 | 未匹配。不是Game Big Win大奖飘屏，更不是全屏中奖动画；不能用在E14所有大奖事件。 |
| A04 | [直播间封面列表-房间状态/lucky gift.webp](</Users/huili/Downloads/房间动效文件/直播间封面列表-房间状态/lucky gift.webp>) | 186×135 | 16 | 房间列表封面的幸运礼物状态。 | 未匹配；外围素材索引，不等于面板SUPER或中奖气泡。 |
| A05 | [直播间封面列表-房间状态/chatting.webp](</Users/huili/Downloads/房间动效文件/直播间封面列表-房间状态/chatting.webp>) | 84×60 | 16 | 房间列表聊天状态。 | 未匹配；不扩大本轮礼物开发范围。 |
| A06 | [直播间封面列表-房间状态/pk.webp](</Users/huili/Downloads/房间动效文件/直播间封面列表-房间状态/pk.webp>) | 122×94 | 16 | 房间列表PK状态。 | 未匹配；外围索引。 |
| A07 | [直播间封面列表-房间状态/bigwin.webp](</Users/huili/Downloads/房间动效文件/直播间封面列表-房间状态/bigwin.webp>) | 132×102 | 19 | 房间列表Big Win状态。 | 未匹配；不作为房内大奖全屏素材。 |
| A08 | [直播间封面-声波动效/直播间封面-声波动效.webp](</Users/huili/Downloads/房间动效文件/直播间封面-声波动效/直播间封面-声波动效.webp>) | 40×40 | 24 | 房间封面的声波。 | 未匹配；不作为麦位魔法/大头表情。 |
| A09 | [app首页，直播间收起-缩小声波/直播间缩小声波 导出.webp](</Users/huili/Downloads/房间动效文件/app首页，直播间收起-缩小声波/直播间缩小声波 导出.webp>) | 206×206 | 26 | 首页/最小化房间入口声波。 | 未匹配；Keep业务已有，不据此认定最小化功能缺失。 |
| A10 | [私聊-直播间名片 波纹/私聊-直播间名片 波纹.webp](</Users/huili/Downloads/房间动效文件/私聊-直播间名片 波纹/私聊-直播间名片 波纹.webp>) | 96×56 | 24 | 私聊中的房间名片波纹。 | 未匹配；消息卡片外围索引。 |
| A11 | [游戏大厅 朋友在玩 直播节奏/1_00000_iSpt.webp](</Users/huili/Downloads/房间动效文件/游戏大厅 朋友在玩 直播节奏/1_00000_iSpt.webp>) | 57×49 | 18 | 好友在玩/大厅直播节奏标记。 | 未匹配；外围索引。 |
| A12 | [派对封面-join/1_00000_iSpt.webp](</Users/huili/Downloads/房间动效文件/派对封面-join/1_00000_iSpt.webp>) | 48×40 | 32 | 派对封面Join入口。 | 未匹配；不能因与A11同名就去重。 |
| A13 | [partying好友派对页面/party 按钮.webp](</Users/huili/Downloads/房间动效文件/partying好友派对页面/party 按钮.webp>) | 198×56 | 16 | 好友派对页按钮。 | 未匹配；外围索引。 |
| A14 | [partying个人主页/partying个人主页.webp](</Users/huili/Downloads/房间动效文件/partying个人主页/partying个人主页.webp>) | 170×56 | 16 | 个人主页Partying状态。 | 未匹配；外围索引。 |
| A15 | [音乐播放器-loading动画/loading.webp](</Users/huili/Downloads/房间动效文件/音乐播放器-loading动画/loading.webp>) | 321×321 | 24 | 音乐播放器加载。 | 未匹配；目录中的loading.png是静态参考，不替代该动画。 |
| A16 | [音乐播放器-loading动画/直播间-个人卡片-送礼按钮.webp](</Users/huili/Downloads/房间动效文件/音乐播放器-loading动画/直播间-个人卡片-送礼按钮.webp>) | 84×84 | 10 | 内容与A02完全相同的用户卡礼物按钮，放在音乐目录中。 | 与A02同哈希；不是音乐loading，复用已接入A02，不重复打包。 |
| A17 | [优惠小弹窗/2_00000_iSpt.webp](</Users/huili/Downloads/房间动效文件/优惠小弹窗/2_00000_iSpt.webp>) | 87×86 | 16 | 优惠小弹框。 | 未匹配；触发条件及账户资格不能由素材推导。 |
| A18 | [直播间首页-日签宝箱/每日钱包宝箱.webp](</Users/huili/Downloads/房间动效文件/直播间首页-日签宝箱/每日钱包宝箱.webp>) | 204×200 | 32 | 首页日签宝箱。 | 未匹配；不自动接领取/奖励逻辑。 |
| A19 | [底部导航栏/主页.webp](</Users/huili/Downloads/房间动效文件/底部导航栏/主页.webp>) | 176×176 | 6 | 底栏首页选中动画。 | 与[已打包文件][tab-home]同哈希；不是缺失资源。 |
| A20 | [底部导航栏/直播.webp](</Users/huili/Downloads/房间动效文件/底部导航栏/直播.webp>) | 176×176 | 6 | 底栏Party选中动画。 | 与[已打包文件][tab-party]同哈希；不是缺失资源。 |
| A21 | [底部导航栏/信息.webp](</Users/huili/Downloads/房间动效文件/底部导航栏/信息.webp>) | 176×176 | 6 | 底栏消息选中动画。 | 与[已打包文件][tab-messages]同哈希；不是缺失资源。 |
| A22 | [底部导航栏/我的.webp](</Users/huili/Downloads/房间动效文件/底部导航栏/我的.webp>) | 176×176 | 6 | 底栏Profile选中动画。 | 与[已打包文件][tab-profile]同哈希；不是缺失资源。 |

22个文件中A02/A16重复，实际21份不同内容。开发前有4份与项目资源完全一致；第一批新增A01/A02后，共6份不同内容已打包（7个源路径可匹配，A16与A02重复），其余15份不同内容未匹配到同文件。这个统计是资源去重结果，不是缺失功能数量。

本地目录没有SVGA/PAG/VAP/MP4文件，不能提供23档数字、三档中奖、全房散开或座驾等全部素材；对应候选已在第3节列出，无需再让用户寻找已经能从Nady取得的文件。

## 5. 后续接入与资源验收

### 2026-11-15第二批接入

- `big_rocket_fly_lv1..6.mp4`、`jackpot_gift_panel_anim.mp4`原样取自Nady动画目录，AppAssets及`assets/room_gift/manifest.json`记录来源和校验值。SUPER背景原样取自Nady图片目录，放入房间UI图片目录并记录在Lanhu房间manifest，明确其Nady来源。
- 已实际读取VAP元数据：火箭`user`为图片、`name`为文字；`jackpot_full_screen_anim.mp4`的`gift`为图片；面板SUPER装饰无动态槽。未声明的槽位不猜测、不下载无关头像。
- 新面板预览按本地PRD适配，并非声称Nady有同款独立预览窗。Game Big Win全屏素材仍缺失，用户已确认稍后补充；游戏面板顶部横幅继续禁止用于替代大奖全屏。
- 第二批截图存于`test/goldens/room_gift_panel_v3/`；普通面板、幸运记录和SUPER区域按320/375/430检查，历史图片保持原样。物理Android/iOS的槽位合成与静音结果仍需另记。

1. **先确认语义再接入。** 对照同目录定位图、蓝湖上下文与Nady调用点；不得仅按“bigwin”“gift”或文件名复用。
2. 图标和按钮动效使用房间资源目录中的语义化文件名；Nady礼物重动画沿用独立动效目录。AppAssets、manifest和pubspec在实际接入批次同步维护，记录蓝湖image_id/图层、用户本地原路径或Nady原路径，不冒充另一来源。
3. 22个WebP已确认包含动画帧；第一批A01/A02已通过Flutter真实codec多帧解码。其余文件的实际解码，以及真机循环/单次行为、可见性暂停、重复打开及释放仍待验证。大图标不能按原始像素直接撑大既有按钮，显示尺寸用theme管理。
4. 静态稿中的进度条、按钮、金额、滑杆和倒计时均用真实可交互控件/文字实现。图片不能替代功能；需要新基线时独立命名并人工核对，不覆盖历史基线掩盖变化。
5. 后续需记录Android/iOS播放和透明合成、静音、槽位替换、损坏资源、路由覆盖及释放结果。第一批另补真实codec多帧解码及Widget布局测试；没有真机送礼或原生播放验收。

[audit]: /Users/huili/project/iSnow/docs/room_gift_flow/requirements_gap_audit.md
[feishu]: https://am68xzq9sv.feishu.cn/wiki/G7lZwd6kFid7XjkmgWeck6XYngb
[lanhu]: https://lanhuapp.com/web/#/item/project/stage?tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6&pid=9ab318f9-4876-4218-a940-73d4c98780c2
[asset-root]: /Users/huili/Downloads/房间动效文件
[nady-animation-root]: /Users/huili/nady/assets/animations
[asset-policy]: /Users/huili/project/iSnow/docs/room/room_ui_asset_policy.md
[theme-policy]: /Users/huili/project/iSnow/docs/ui_theme_guidelines.md
[lh-gift-main]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=dd85e4a7-00f5-41c9-a75b-b28a25da69ad&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-gift-none]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=714de4f4-6a54-4b2f-a3a0-14c3ad91167f&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-gift-empty]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=9bd2450c-0a47-448c-a450-936428413346&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-gift-expanded]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=cb3f0c2a-91aa-4ed7-b5cc-e2a6c2ada4d6&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-gift-flow]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=e459e31d-0447-43c5-81c8-5b4be084307e&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-room-materials]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=4a6d40ff-2e2b-4d9d-b6d1-dff21fe18895&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[lh-room-chat]: https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=cc03dc0c-a1e5-4dcc-ba8f-6bb2cfd909d2&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6
[chat-ui]: /Users/huili/project/iSnow/docs/room/room_public_chat_ui.md
[asset-script]: /Users/huili/project/iSnow/tools/download_lanhu_room_assets.py
[app-assets]: /Users/huili/project/iSnow/lib/theme/app_assets.dart:67
[lanhu-manifest]: /Users/huili/project/iSnow/assets/lanhu/room/lanhu_room_assets_manifest.json
[gift-manifest]: /Users/huili/project/iSnow/assets/room_gift/manifest.json
[nady-gift-player]: /Users/huili/nady/lib/pages/room/voice_room/widgets/gift_effect/nady_room_gift_widget.dart:12
[nady-gift-layer]: /Users/huili/nady/lib/pages/room/voice_room/widgets/gift_effect/nady_room_gift_layer.dart:9
[nady-gift-panel]: /Users/huili/nady/lib/widgets/gift_panel/gift_panel_widget.dart:109
[nady-jackpot-panel]: /Users/huili/nady/lib/pages/room/voice_room/widgets/jackpot/jackpot_panel_banner.dart:22
[nady-jackpot-number]: /Users/huili/nady/lib/pages/room/voice_room/widgets/jackpot/jackpot_rolling_number.dart
[nady-lucky-num]: /Users/huili/nady/lib/pages/room/voice_room/widgets/luck_effect/nady_room_lucky_num_layer.dart:95
[nady-lucky-bubble]: /Users/huili/nady/lib/pages/room/voice_room/widgets/luck_effect/nady_room_lucky_layer.dart:35
[nady-close-icon]: /Users/huili/nady/assets/images/ic_outline_close.webp
[nady-gift-track]: /Users/huili/nady/lib/pages/room/voice_room/widgets/gift_flowing_v2/nady_gift_flowing_widget.dart
[nady-entrance]: /Users/huili/nady/lib/pages/room/voice_room/widgets/vehicle_effect/nady_enter_room_animation.dart
[nady-vehicle]: /Users/huili/nady/lib/pages/room/voice_room/widgets/vehicle_effect/nady_room_vehicle_layer.dart
[nady-degrade]: /Users/huili/nady/lib/utils/nady_gift_degrade_policy.dart
[nady-fps]: /Users/huili/nady/lib/utils/nady_fps_monitor.dart:17
[current-gift-button]: /Users/huili/project/iSnow/lib/classes/room/views/room_bottom_bar.dart:156
[current-member-gift]: /Users/huili/project/iSnow/lib/classes/room/interaction/room_member_card_content.dart:345
[tab-home]: /Users/huili/project/iSnow/assets/lanhu/tabbar/shell_home_active.webp
[tab-party]: /Users/huili/project/iSnow/assets/lanhu/tabbar/shell_party_active.webp
[tab-messages]: /Users/huili/project/iSnow/assets/lanhu/tabbar/shell_messages_active.webp
[tab-profile]: /Users/huili/project/iSnow/assets/lanhu/tabbar/shell_profile_active.webp

## 6. 2026-11-16资源与布局增量

- Nady 23个`luck_num{n}.mp4`和`luck_win_small/medium/big.mp4`均已接入`assets/room_gift/`，AppAssets、来源路径和SHA-256同步维护。原始VAP画布750×1624，数字在整屏透明画布内自身定位，不再塞入底部通用文字卡。
- 数字实际仅声明`text`；三种气泡实际均声明`Avatar`、`Win`、`Times`。只按已验证元数据替换，不添加素材未声明的昵称槽位。
- 进场条布局参考Nady `nady_voice_room_enter_layer.dart`及`nady_enter_room_animation.dart`，251×56、头像48、约5秒滑入停留滑出；颜色/文字沿用iSnow theme，尺寸集中AppSpacing。头像、头像框及条底图来自事件，未复制示例用户装饰。
- `specialEffects.animationUrl`用于进场条，`vehicle.animationUrl`用于共享全屏座驾；二者同进场对象关联。麦位头像框来自真实`avatarWidget`，临时层使用事件的魔法动画/表情`dynamicPic`。
- 所有历史截图保留，本轮不以静态截图或素材存在代替Android真机播放验收；实现范围和剩余项以盘点8.10为准。

## 7. 账号飘屏增量（2026-11-20）

- 横幅背景与前景来自Nady事件的`bannerEffectUrl/effectUrl/upperEffect`、贵族的`onlineAnimationUrlBg/onlineAnimationUrlForward`或`upLevelAnimationUrlBg/upLevelAnimationUrlForward`。均使用现有匿名资源缓存；没有凭空裁剪设计示例图或新增Flutter Icon。
- 视觉层参考Nady `gift_barrage_layer.dart`、`long_link_global_handler.dart`和`game_notify_barrage_list.dart`的消息类型与位置。账号根叠层统一展示，头像/礼物/奖励/贵族图标均来自实际事件；火箭入口复用既有`roomRocketStages`图，独立全屏复用已核对的lv1～6 VAP，SUPER继续使用已验证的gift槽位。
- Game Big Win事件没有独立动画URL；现有游戏邀请横幅不适用。Nady有程序绘制的金币雨组件，但本轮仍按用户已确认方案等待独立全屏素材，不将程序候选或奖品弹框记作素材需求完成。
- 本轮没有新增静态素材，主题参数集中`room_barrage_theme.dart`，新截图使用`room_barrage_v1`独立命名。真实媒体播放与设备画面仍需后续Android只读/隔离专项，不复用历史真机结果冒充本轮验证。
