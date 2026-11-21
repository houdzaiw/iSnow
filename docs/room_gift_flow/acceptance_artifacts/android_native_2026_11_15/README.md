# Android原生播放器验收证据（2026-11-15）

设备为Pixel_9 / Android 15 / ARM64。测试使用独立包
`com.isnow.qa.room_gift_native_acceptance`，直接编译当前工作区的播放器、
全屏层和本地插件，不登录、不接入钱包、Socket或送礼接口。

- `native_result.json`：9项不同的Android原生用例全部通过。
- `svga_repository_result.json`：原始仓库SVGA样例额外1项可见画面检查通过。
- `verification.json`：10项原生用例、758项房间回归、源码和APK哈希、
  ARM64及新停止协调器的打包检查结果。
- `native_*.png`：5张通过像素检查的截图，排除Debug角标并比较画面与背景，
  没有以纯透明首帧作为可见播放通过依据。这些是验收帧，不是UI截图基线。
- `initial_transparent_frames/`：保留最初过早/未连续泵帧的截图，以及失败的
  像素检查记录。它们不是通过证据；未覆盖或删除历史golden。

实测覆盖SVGA/PAG/MP4/VAP初始化及自然结束、MP4静音、PAG真实初始化回执
延迟下的关闭、PAG释放后交接MP4、VAP停止等待销毁、真实配置回执延迟时
取消且不迟到起播，以及23秒循环样例跨过原20秒期限。

截图初次空白的测试基础设施原因是默认live-test策略不连续推进Dart动画，
且Native playPath回执早于实际开始渲染。最终显式使用fullyLive、等待VAP
真实onStart并保留有效画面间隔；原始仓库SVGA样例也未修改地复验通过，
没有为消除空白而修改生产SVGA画笔或降低像素检查阈值。

素材仅用于内部技术验收：SVGA沿用现有样例和Nady的luck_gift.svga，PAG
沿用现有combo动画，VAP沿用Nady无动态槽位的开袋素材，普通MP4及长循环
VAP1样例由本地FFmpeg生成。源码、资源及生成方式见
`tools/room_gift_native_acceptance/README.md`。

本证据不认证iOS、真实双机广播、收费连击、各类动态用户/礼物槽位、所有
透明模式与方向、实际音频收听或性能帧率。运行中的iSnow没有被本次修复包
替换，Android原生修复需安装并重启后才能在该App会话生效。
