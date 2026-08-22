# UI Theme Guidelines

本文档是 iSnow 项目的全局 UI 开发规范。所有新建 UI、修改已有 UI、以及基于蓝湖 MCP 设计稿落地的页面，都必须先遵守本文档，再编写页面代码。

## 适用范围

- 适用于 `lib/classes/`、`lib/widgets/`、`lib/manager/app_shell.dart` 等所有 Flutter UI 代码。
- 适用于蓝湖 MCP 设计稿迁移、图片资源下载、icon 使用、页面视觉还原。
- 适用于新增页面，也适用于后续改动时触碰到的现有页面。
- Room 相关页面还必须同时遵守 `docs/room/room_ui_asset_policy.md`，若两份文档都有要求，执行更严格的规则。

## 核心原则

1. 页面只负责组合 UI，不直接定义视觉 token。
2. 所有颜色、渐变、圆角、间距、尺寸、字体、阴影、图片和 icon，必须先进入 `lib/theme/` 对应文件，再由页面引用。
3. 新增 token 前必须先查找能否复用现有 token；只有不能复用时才新增。
4. 蓝湖 MCP 资源必须下载到 `assets/lanhu/{module}/` 并声明到 `AppAssets` 后才能使用。
5. 全项目禁止使用 Flutter `Icon` 和 `Icons.*`。所有 icon 必须使用图片资产；资源缺失时使用全局红色 missing placeholder。

## Theme 文件职责

| 文件 | 职责 | 页面使用方式 |
| --- | --- | --- |
| `lib/theme/app_theme.dart` | ThemeData 入口，并统一 export 所有 theme token | 页面优先 `import '../../theme/app_theme.dart';` |
| `lib/theme/app_colors.dart` | 所有纯色 token | 使用 `AppColors.xxx` |
| `lib/theme/app_gradients.dart` | 所有渐变 token | 使用 `AppGradients.xxx` |
| `lib/theme/app_spacing.dart` | 所有间距和尺寸 token | 使用 `AppSpacing.xxx` |
| `lib/theme/app_radius.dart` | 所有圆角半径和 BorderRadius token | 使用 `AppRadius.xxx` |
| `lib/theme/app_text_styles.dart` | 所有 TextStyle token | 使用 `AppTextStyles.xxx` |
| `lib/theme/app_shadows.dart` | 所有 BoxShadow token | 使用 `AppShadows.xxx` |
| `lib/theme/app_assets.dart` | 所有图片、背景、icon 资源路径 | 使用 `AppAssets.xxx` |

除非正在编辑 theme 文件本身，否则页面和组件应从 `app_theme.dart` 统一导入 theme token，不要分散导入多个 theme 文件。

## 禁止写法

页面、组件、弹窗、列表项、导航栏、底部栏中禁止直接写以下内容：

```dart
Color(0xFFFF5390)
Colors.white
LinearGradient(...)
TextStyle(...)
BorderRadius.circular(12)
Radius.circular(12)
BoxShadow(...)
EdgeInsets.all(12)
SizedBox(width: 12)
'assets/lanhu/base/nav_back.png'
Icon(Icons.close)
Icons.arrow_back
```

必须改为：

```dart
decoration: const BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: AppRadius.cardBorder,
  boxShadow: AppShadows.soft,
);

const SizedBox(height: AppSpacing.xl);

Image.asset(
  AppAssets.navBack,
  width: AppSpacing.iconSizeMd,
  height: AppSpacing.iconSizeMd,
);
```

## Colors

所有纯色统一放入 `AppColors`。

新增颜色前必须先检查现有 token：

- 品牌与主按钮色：优先查找 `primaryPink`、`primaryPinkDeep`、`primaryPinkLight`、`brandYellow`、`accentYellow`。
- 背景色：优先查找 `pageBackground`、`warmBackground`、`warmBackgroundEnd`、`creamBackground`、`cardBackground`、`fieldBackground`。
- 文本色：优先查找 `textPrimary`、`textBody`、`textSecondary`、`textTertiary`、`textPlaceholder`、`textInverse`。
- 分割线与边框：优先查找 `divider`、`border`、`calendarBorder`、`neutralLight`。
- 状态色：优先查找 `danger`、`missingAsset`。

新增颜色命名必须表达用途，不使用设计稿图层名或十六进制值作为名称。

```dart
// Good
static const Color badgeBackground = Color(0xFFFFF2D7);

// Bad
static const Color colorFFEAB1 = Color(0xFFFFEAB1);
static const Color rectangle123 = Color(0xFFFFEAB1);
```

## Gradients

所有渐变统一放入 `AppGradients`。

新增渐变前必须先检查现有 token，例如 `pageBackground`、`authBackground`、`primary`、`sendButton`、`voiceBubble`。

页面只允许引用渐变 token：

```dart
decoration: const BoxDecoration(
  gradient: AppGradients.authBackground,
);
```

渐变内的颜色若会在纯色场景复用，应先沉淀到 `AppColors`；如果仅用于该渐变，可以保留在 `AppGradients` 内部。

## Spacing And Sizes

所有间距、组件尺寸、icon 尺寸、头像尺寸、按钮高度、导航高度、卡片固定尺寸，都统一放入 `AppSpacing`。

现有通用间距 token：

| Token | Value |
| --- | --- |
| `xxs` | 2 |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 10 |
| `lg` | 12 |
| `xl` | 16 |
| `xxl` | 20 |
| `xxxl` | 24 |
| `section` | 32 |

新增尺寸使用偏通用语义命名，不使用页面名、蓝湖图层名、或纯数字命名。

推荐命名：

```dart
static const double iconSizeSm = 16;
static const double iconSizeMd = 24;
static const double iconSizeLg = 44;
static const double controlHeightSm = 36;
static const double controlHeightMd = 44;
static const double controlHeightLg = 61;
static const double avatarSizeSm = 32;
static const double avatarSizeMd = 48;
static const double avatarSizeLg = 72;
static const double tabBarHeight = 54;
```

禁止命名：

```dart
static const double loginButtonHeight = 61;
static const double lanhuRect123Width = 298;
static const double size61 = 61;
```

若某个尺寸确实只属于一个复杂组件，优先抽取为组件私有常量；但只要跨页面、跨组件或来自设计系统重复出现，必须沉淀到 `AppSpacing`。

## Radius

所有圆角统一放入 `AppRadius`。

页面不得直接写 `BorderRadius.circular(...)` 或 `Radius.circular(...)`。新增圆角时先检查现有 token：

- `xs`、`sm`、`md`、`lg`、`xl`
- `card`、`calendar`、`dialog`、`homeCard`、`homeCardContent`、`pill`
- `cardBorder`、`fieldBorder`、`dialogBorder`、`sheetBorder`、`pillBorder`

优先复用已有 `BorderRadius` 常量；如果只有半径值可复用，也应引用 `AppRadius.xxx`。

## Text Styles

所有字体样式统一放入 `AppTextStyles`。

页面不得直接写 `TextStyle(...)`。新增文本样式前先检查：

- 导航标题：`navTitle`
- 页面或模块标题：`title`
- 按钮文字：`button`
- 正文：`body`、`bodySmall`
- 强调正文：`bodyStrong`、`bodyStrongSmall`
- 菜单：`menuItem`
- 辅助说明：`caption`
- 输入提示：`hint`、`hintLarge`
- 时间或极小文字：`timeTiny`
- 日历日期：`calendarDay`

当只需要变更颜色、字号、字重中的一项时，可以基于现有 token `copyWith`，但新增的颜色、字号、字重仍必须来自 theme token。

```dart
Text(
  title,
  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryPink),
);
```

## Shadows

所有阴影统一放入 `AppShadows`。

页面不得直接写 `BoxShadow(...)`。新增阴影前先检查：

- `soft`
- `button`

新增阴影命名必须表达使用场景或强度，例如 `cardSoft`、`floatingBar`、`pressedButton`。

## Assets And Icons

所有图片、背景图、icon 路径统一放入 `AppAssets`。

页面不得直接写资源路径字符串。资源使用流程：

1. 通过蓝湖 MCP 下载资源。
2. 放入 `assets/lanhu/{module}/`。
3. 确认 `pubspec.yaml` 已覆盖该资源目录。
4. 在 `AppAssets` 中新增常量。
5. 页面通过 `Image.asset(AppAssets.xxx)` 使用。

资源文件命名使用 snake_case：

```text
assets/lanhu/profile/menu_about.png
assets/lanhu/rank/top1_card.png
assets/lanhu/base/nav_back.png
```

`AppAssets` 常量名采用 camelCase，目录已经表达模块时，常量名尽量短：

```dart
// Good
static const String navBack = 'assets/lanhu/base/nav_back.png';
static const String menuAbout = 'assets/lanhu/profile/menu_about.png';
static const String top1Card = 'assets/lanhu/rank/top1_card.png';

// Avoid
static const String lanhuProfileMenuAboutIcon = 'assets/lanhu/profile/profile_menu_about.png';
```

若为了兼容已有代码已经存在较长常量名，不必立即大范围重命名；后续触碰到相关页面时再逐步治理。

## Missing Placeholder

全项目使用一个全局红色 missing placeholder，禁止各模块自行维护多个占位 icon。

当前已有资源：

```text
assets/lanhu/room/room_icon_missing.png
```

后续应迁移为全局资源：

```text
assets/lanhu/common/icon_missing.png
```

并在 `AppAssets` 中提供统一常量：

```dart
static const String iconMissing = 'assets/lanhu/common/icon_missing.png';
```

在全局资源迁移完成前，新功能如遇缺失资源，应优先新增全局 missing placeholder，而不是继续新增模块级 missing placeholder。

## Lanhu MCP Implementation Flow

基于蓝湖 MCP 创建或迁移 UI 时，必须按以下流程执行：

1. 读取设计稿，识别页面结构、图片资源、颜色、渐变、字体、圆角、阴影、间距和尺寸。
2. 下载图片和 icon 到 `assets/lanhu/{module}/`，缺失资源使用全局 missing placeholder。
3. 在 `AppAssets` 中声明所有资源路径。
4. 对照 `AppColors`、`AppGradients`、`AppSpacing`、`AppRadius`、`AppTextStyles`、`AppShadows` 查找可复用 token。
5. 仅在无法复用时新增 token，并使用通用语义命名。
6. 页面实现时只引用 `AppTheme` 导出的 token。
7. 实现后检查是否存在裸视觉值和 `Icons.*`。

## Existing UI Cleanup

现有页面采用逐步治理规则：

- 不要求一次性重构全项目已有裸值。
- 后续修改某个页面或组件时，必须顺手治理触碰范围内的裸颜色、裸尺寸、裸字体、裸圆角、裸阴影、裸资源路径和 `Icons.*`。
- 如果某个裸值被多个页面复用，应先沉淀为 theme token，再替换引用。
- 如果治理会明显扩大改动范围，应在当前 PR 或任务说明中记录遗留项。

## Review Checklist

提交前必须检查：

- [ ] 页面没有直接写 `Color(0x...)` 或 `Colors.*`。
- [ ] 页面没有直接写 `LinearGradient(...)`。
- [ ] 页面没有直接写 `TextStyle(...)`。
- [ ] 页面没有直接写 `BorderRadius.circular(...)` 或 `Radius.circular(...)`。
- [ ] 页面没有直接写 `BoxShadow(...)`。
- [ ] 页面没有直接写图片路径字符串。
- [ ] 页面没有使用 `Icon` 或 `Icons.*`。
- [ ] 页面 padding、margin、gap、width、height、icon size、avatar size、button height 等来自 `AppSpacing`。
- [ ] 蓝湖资源已经放入 `assets/lanhu/{module}/`。
- [ ] 蓝湖资源已经声明到 `AppAssets`。
- [ ] 新增 token 已先确认无法复用现有 token。
- [ ] 修改已有页面时，触碰范围内的裸视觉值已同步治理。

