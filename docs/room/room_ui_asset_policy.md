# Room UI Asset Policy

房间语聊 UI 必须严格执行以下资源规则。

## Lanhu Asset Download

- 蓝湖 MCP 设计稿中的房间图标、切图、徽章等图片资源，必须自动下载到 `assets/lanhu/room/`。
- 自动下载使用 `tools/download_lanhu_room_assets.py`：
  ```bash
  python3 tools/download_lanhu_room_assets.py "lanhu-mcp/data/lanhu_designs/<project_id>/二十麦位.html"
  ```
- 下载后的文件必须使用稳定的语义化文件名，例如 `room_bottom_chat.png`、`room_mic_seat.png`，不要在业务代码中引用蓝湖临时类名或 `thumbnail_*.png`。
- 下载来源和文件映射需要保留在 `assets/lanhu/room/lanhu_room_assets_manifest.json`，方便后续核对和替换。
- `pubspec.yaml` 必须包含 `assets/lanhu/room/`。

## Flutter Room UI

- `lib/classes/room/` 下的页面和组件禁止使用 Flutter 内置 `Icon`/`Icons.*` 作为视觉图标。
- 房间 UI 的按钮、麦位、底部工具栏、提示、管理操作等图标必须使用 `Image.asset` 或封装后的图片组件。
- 如果蓝湖设计稿有对应图标，必须优先使用设计图标。
- 如果蓝湖设计稿没有对应图标，必须使用 `assets/lanhu/room/room_icon_missing.png` 作为红色缺省图，明确标记“等待后续补图”，不能临时改回 Flutter icon。

## Replacement Rule

后续补齐图标时，只替换 `assets/lanhu/room/` 下的语义化图片文件或更新 `AppAssets` 常量，不要改动业务逻辑。
