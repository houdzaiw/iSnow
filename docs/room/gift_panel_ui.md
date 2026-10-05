# Gift Panel UI

## Design

- 蓝湖设计：`dd85e4a7-00f5-41c9-a75b-b28a25da69ad`，375 x 812。
- 顶部横幅、横排接收人、右侧筛选、可滑动分类、固定背包入口、两行四列礼物、分页短线、余额及粉色渐变 Send。
- 面板位于 root navigator，不受房间底部导航遮挡。内容高度适配屏幕，底部保留系统安全区，不绘制设计稿的系统 home indicator。

## View Structure

- `room_gift_sheet.dart`：订阅 ViewModel，组合面板，展示 loading/error/empty，返回发送或打开钱包结果。
- `room_gift_promotion_bar.dart`：蓝湖横幅。充值入口复用钱包结果；活动图优先使用所选礼物的 `banner`，无数据时展示设计稿静态横幅。该静态图不是实时活动数据，也没有伪造活动跳转链接。只有接口提供有效 HTTP(S) `jumpLink` 时才可点击进入现有 WebView，保留原 URL 参数并增加当前语言。
- `room_gift_target_bar.dart`：真实接收人头像和麦位序号；筛选、单人/多人选择交给 ViewModel。
- `room_gift_grid.dart`：ExtendedTabBar + ExtendedTabBarView 同步分类，背包按钮固定在右侧，背包为空仍可切回普通分类。
- `room_gift_pages.dart`：每页八个礼物；内层 ExtendedTabBarView 在分页边界联动外层分类。分页位置是纯 UI 状态，不进入业务缓存；切回分类时定位到 ViewModel 当前选中的礼物，避免发送不可见的旧页礼物。
- `room_gift_footer.dart`：余额进入钱包；最多四个接口配置的快捷数量，展开菜单保留全部数量及自定义数量；提交仍走原 ViewModel。

## Data And Assets

- 不改变 RoomGiftManager 单例缓存、启动预加载、Repository 请求或发送接口。重复打开仍优先使用缓存。
- 所有业务数据保持来自现有 Model；补充 `banner` / `jumpLink` 字段，与 Nady 返回数据兼容。
- 图片缺失继续使用红色缺省图，不使用 Flutter Icon/Icons。
- 资源位于 `assets/lanhu/room/room_gift_*.png`，来源记录在同目录 manifest，pubspec 已覆盖该目录。
- 重新下载：
  ```bash
  python3 tools/download_lanhu_room_assets.py --design-url "https://lanhuapp.com/web/#/item/project/detailDetach?pid=9ab318f9-4876-4218-a940-73d4c98780c2&image_id=dd85e4a7-00f5-41c9-a75b-b28a25da69ad&tid=7aacbbd3-8118-4f56-b35e-8ce2cb33a5c6"
  ```

## Verification

- `test/room_gift_sheet_test.dart`：分类/分页边界、固定背包、数量和接收人发送、充值导航，以及 320/375/430 宽度的长文本、安全区布局。
- `test/goldens/room_gift_panel_*.png`：离线 UI 快照；模拟礼物无图片，红色图属于预期缺省状态，不代表线上礼物图片加载失败。
- Model、ViewModel 和 Manager 测试继续验证真实字段映射、送礼规则和缓存复用。
