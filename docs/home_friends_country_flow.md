# Friends Activity 与首页国家筛选

## 页面与入口

- 首页 Friends Activity 和完整好友页共用 `friendsActivityProvider`。空列表仍显示 All 与真实空状态，不生成假头像。
- All 打开 `/party/friends-activity`，默认 Friends are playing。与 Recent Footprints 使用 ExtendedTabBar / ExtendedTabBarView，支持点击和左右滑动，各自保留滚动位置。
- 进入完整页面后台刷新一次好友列表，同键并发刷新合并；下拉刷新同步首页。切分类不额外刷新好友列表。
- 足迹在首次切入时加载，每页 20 条，以房间 ID 去重。刷新、加载更多及错误重试分别管理，刷新失败不误请求下一页。关闭完整页面释放足迹状态。
- 头像、好友房间和足迹统一调用 `openHomeActivityRoom` → `enterSharedRoom`，传真实 `roomId` 和记录的 `uid`。新增可选 `followUid=0`，仅正数加入路由查询，兼容现有调用。
- 沿用锁房密码、切房确认和当前房间恢复。重复点击被合并；关闭来源页面或账号会话失效后不执行迟到进房。
- 自己房间按持久化用户的 `roomId` 判断，展示简介；其他房间使用 Nady 对应关系说明。麦上人数大于 0 时展示 Partying。
- 首页徽标顺序为 `label=1` 大厅、`label=2` 挖矿、火箭 `showStatus=2/3`、`inMicNum>0` 语聊，否则隐藏。火箭等级使用已有等级图片，不按列表序号生成状态。

## 国家筛选

- 默认 Hot；完整国家列表来自首页国家接口，保留服务端顺序、统一大写代码、按代码去重，不使用登录区号列表代替。
- 横向栏不再截取前五个国家。点击、左右滑动及 Countries 弹层选择共用一个选中状态，选择后定位对应 Tab。
- More 从根导航打开约六成屏高的白色弹层，三列网格包含 Hot、国旗、名称和选中态。点击立即选择并关闭，遮罩取消不改变状态。
- 国家加载、错误和重试独立于 Hot 推荐。国家请求失败保留已取得列表供重试；服务端成功返回的新列表不含当前选择时回到 Hot。
- `homeCountryRoomsProvider(countryCode)` 分别保存每个国家的房间列表、加载、错误和刷新状态，当前应用会话内按需复用。切换失败展示目标国家错误，不显示其他国家的房间。
- 本次不扩展首页推荐分页，仅足迹分页。

## 接口契约

全部路径集中在 `HttpApi`，Repository 使用现有 `HttpDioManager`；业务错误通过现有错误格式化器优先显示服务端 `msg`。

| 用途 | 方法与路径 | 参数 |
| --- | --- | --- |
| 好友在玩 | GET `/api/user/homepage/friends/play` | 无 |
| 最近足迹 | GET `/api/follow/room/queryRelated` | `type=2, page, pageSize=20` |
| 首页国家 | GET `/country-list/home/default-country` | 无 |
| 国家房间 | GET `/api/home/room/recommend` | `page=1`，国家传 `country=ISOCode`，Hot 不传 country |

`homeResponseRows` 先核对业务响应，再解析列表或 Nady 的 data/list 包装；空结果正常展示空状态，结构异常不会伪装为成功列表。

## 分层与生命周期

- Model：独立好友、足迹、推荐房间模型；复用 `CountryInfo`。
- Repository：好友活动和首页 API、当前用户所属房间读取。
- ViewModel：共享好友列表、分页足迹、国家选择及各国家列表；View 只渲染、转发点击和导航事件。
- `HomeFeedSession` 监听现有 `AuthSession`，登录会话变化时增加代次，包括同账号重新登录。相关 Provider 重建、选择回到 Hot，旧异步结果不能回写新账号。
- 所属好友页面、国家弹层及密码弹层按生命周期清理；不新建 Socket、Agora 或 IM 监听。
- 筛选与列表缓存仅在内存保存，不增加插件或持久化表。

## 视觉与资源来源

- 所有新增视觉参数在 `lib/theme/home_activity_theme.dart`，沿用项目字体与浅色主题。
- 新增 `assets/lanhu/party/friends_activity_hall.webp`，来自 Nady 的 `assets/images/ic_home_hall_icon.webp`，并非蓝湖导出。
- 其他徽标、火箭、返回图片复用现有 `AppAssets`；来源记录在 `assets/lanhu/party/home_activity_assets_manifest.json`。
- 现有 `pubspec.yaml` 已声明 `assets/lanhu/party/`。不新增 Flutter `Icon` / `Icons.*`，图片失败沿用红色缺省图。

## 自动化验收（2026-11-07）

- 数据测试 10 项：接口参数、响应解析、国家去重、错误 msg、徽标顺序、并发刷新、分页、乱序请求及账号代次保护。
- 页面测试 23 项：空状态、共享刷新、懒加载足迹、Tab/滑动/国家弹层同步、取消与重试、真实 UID、重复点击、锁房、恢复房间和关闭/切账号隔离。
- 新截图目录 `test/goldens/home_activity_v1/`：好友、足迹、国家各 320/375/430，共 9 张。人工检查发现测试标题字体继承为方块后修正了主题字体；历史截图未覆盖。
- 首轮数据、页面、房间及系统进房回归共 654 项通过；最终入口同步及重复点击修正后，聚焦数据、页面、系统进房共 37 项通过。短屏长错误测试还使用真实长错误验证重试和网格可达。
- 2026-11-08 补充生产路由启动检查 1 项通过，直接验证真实 `goRouter` 的好友页命名路由和路径匹配。
- `flutter analyze --no-pub` 与最终 `git diff --check HEAD` 均通过。

## Pixel_9 设备验收（2026-11-08）

沿用已登录的原调试 App，未重装。经用户明确授权热重启一次更新路由表，原登录状态保留，没有自动登录。

已核对以下国家交互：

- Countries 白底三列弹层展示超过五个国家，包含 Hot、国旗和名称。
- 选择 Algeria 后弹层关闭，横向栏自动滚动到对应 Tab，展示该国家真实的 No rooms yet 空状态，没有沿用 Saudi Arabia 的房间数据。
- 内容区向左滑动至 Egypt，横栏同步切换；重新打开弹层时 Egypt 为选中态。点击外部遮罩取消后仍保持 Egypt。
- 切回 Hot 后恢复其已有房间列表，最后通过悬浮入口恢复房间 31（展示 ID 27465417）。

旧调试会话的 All 曾报 `unknown route name: friends-activity`：顶层 `final goRouter` 的旧实例在热重载后保留原路由表。生产路由测试通过；用户授权热重启后，设备上的 All 已正常打开，不再报该错误，无需为旧运行状态改写生产导航逻辑。

已完成好友与足迹的设备核对：

- All 默认进入 Friends are playing，显示真实房名、头像及本人房间简介。
- 点击 Recent Footprints 首次加载，当前账号返回 6 条足迹，展示封面、房名与真实 Partying 在麦状态。
- 左右滑动切换两个分类，Tab 指示与内容同步；切换没有重复请求好友或足迹。
- 好友接口依次请求 3 次：首页首次加载、进入完整页面后台刷新、手动下拉刷新；足迹接口请求 2 次：首次切入、手动下拉刷新。均为 HTTP 200 / 业务 code 200。
- 好友请求参数为空；足迹两次均为 `type=2, page=1, pageSize=20`。当前真实数据不足 20 条，第二页及分页错误重试以自动化替身验证，未宣称设备已验证第二页。
- 按用户授权，最后点击足迹中的 31 恢复原房间。界面确认展示 ID 27465417，运行时确认 `currentRoomId=1925471983338422273, isInRoom=true, isMinimized=false`。
- 热重启后的本轮页面验收日志没有新增路由断言、未处理 Flutter 异常或 RenderFlex 溢出。

本轮设备操作出现一次验收异常：无障碍树与实际截图不同步，一次国家选择误点了 hei 房间卡片并进房。随即停止点击，核对会话并告知用户；获得“恢复原房间 31”的明确授权后，已离开 hei、恢复 31。后续操作改为每次点击前后单独核对即时截图，不再使用滞后的无障碍坐标。未发送消息、送礼或提交管理操作。
