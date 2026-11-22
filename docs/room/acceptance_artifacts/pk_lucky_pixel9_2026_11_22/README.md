# Pixel_9 PK／Lucky Box 只读验收

2026-11-22，按用户要求保留 App，不开始／结束 PK、不发送／领取宝箱。没有改生产代码或更新截图测试基线。

## 调试连接与热重载

- 从当前 Flutter／DDS 进程参数取得上游 VM 地址，再通过 `ext.flutter.connectedVmServiceUri` 读取已有 DDS。完整临时地址仅保留在本机 `/tmp/isnow-pixel9-current-vm.json`，不将调试鉴权路径写入仓库。
- 监听当前 DDS 的 Service 流，确认已有 Flutter Tools 注册的 `s0.reloadSources`，调用该热重载服务，明确 `force=false、pause=false`，没有调用 hotRestart 或启动第二个 App。
- 收到 Success 及两条 IsolateReload；没有 IsolateStart／IsolateExit。前后主进程26357、主 isolate及房间代次1不变。
- 用 VM `getObject/getInstances` 只读核对新控制器已加载及页面状态；没有通过调试表达式调用业务方法或提交接口。

## 画面与交互

| 检查 | 结果 |
| --- | --- |
| More → PK | 新版根导航面板正常打开，图片和文字正常；当前无麦上用户 |
| PK 分类 | 点击 Multi-player、内容区右滑回1V1均正常 |
| PK 时长 | 5／60分钟分别核对状态，恢复3分钟；选手为空，Start PK禁用，未点击 |
| PK 关闭 | 回到原hei房间，没有结束或新建PK |
| More → Lucky Box | 展示真实余额49,855,109，配置加载结束，无错误 |
| Room／World | Room为5000／20000／50000／100000；World为500000／1000000／5000000／10000000，分别切换正常 |
| 金额与选项 | 选择World的1000000、Room的20000；Room人数10、倒计时180均有实际状态回执；没有点击Send |
| 恢复选择 | 恢复Room、5000金币、2人、60秒 |
| 宝箱列表 | 当前真实列表为空，显示No Lucky Boxes；刷新正常结束 |
| 返回层级 | 系统Back从列表回发送面板，再点击关闭回房间，无弹层残留 |

证据截图为本次设备原始画面，见 [PK 1V1](pk_1v1.png)、[多人](pk_multi.png)、[Room](lucky_room.png)、[World](lucky_world.png)、[参数选择](lucky_options.png)、[空列表](lucky_empty_list.png)、[最终房间](final_room.png)。PK未选用户的红色头像占位来自现有缺省图，不代表该图下载失败，不使用样例用户冒充真实选手。

## 状态与请求核对

- 最终仍是hei，内部roomId与进房代次未变；Room／Socket均ready，麦上人数0。
- 余额前后均49,855,109；PK事件为0、无选手，宝箱没有当前开箱任务或领取结果。
- 热重载后的PK详情、宝箱配置／列表、钱包余额响应均为HTTP200／业务200。More素材查询使用原有POST `/api/resource/banner`，属于展示数据读取。
- 日志中PK begin／over、宝箱push／grab、gift/send、mic up／down请求共0条；未发现Flutter异常、资源加载失败或布局溢出。完整分类统计及状态快照见 [verification.json](verification.json)。

当前没有麦上选手及真实宝箱，因此本次没有验证真实计分、选手换麦、PK赢家／结算、宝箱到时开箱和领奖动效；不能以本轮面板通过替代这些业务联调或原生素材性能验收。没有重启、重装、消费、发送消息或提交管理操作，IDE原调试会话仍保留。
