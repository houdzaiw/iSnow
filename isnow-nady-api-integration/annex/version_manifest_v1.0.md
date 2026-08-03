# iSnow Nady 接口接入版本清单 v1.0

生成日期：2026-08-02

## 当前版本产物

| 类型 | 文件 | 说明 |
| --- | --- | --- |
| 初版 PRD 草稿 | `prd/prd_v1.0.html` | 步骤三输出，保留为草稿快照。 |
| 最终版 PRD | `prd/prd_final_v1.0.html` | 步骤六输出，包含目录、版本切换、流程图、原型切片、异常边界、埋点和附件。 |
| 高保真原型 | `prototype/prototype_v1.0.html` | 步骤四输出，包含登录、注册、用户资料、调试日志视图和 focus 模式。 |
| 主流程图 | `flowcharts/core_flow_v1.0.mmd` | 蓝湖功能到接口证据、代码接入和验证总流程。 |
| 登录注册流程图 | `flowcharts/auth_flow_v1.0.mmd` | 国家码、手机号判断、登录和注册流程。 |
| 用户资料流程图 | `flowcharts/profile_flow_v1.0.mmd` | 资料加载、编辑、头像上传和保存流程。 |
| 调试流程图 | `flowcharts/debug_flow_v1.0.mmd` | 接口日志、脱敏、失败分类和 UI 处理流程。 |

## v1.0 锁定规则

- 不直接覆盖任何 `*_v1.0.*` 文件。
- 后续新增或修改蓝湖功能时，先复制对应文件为新版本，例如：
  - `prd/prd_final_v1.0.html` -> `prd/prd_final_v1.1.html`
  - `prototype/prototype_v1.0.html` -> `prototype/prototype_v1.1.html`
  - `flowcharts/auth_flow_v1.0.mmd` -> `flowcharts/auth_flow_v1.1.mmd`
- 新版 PRD 中所有 iframe 原型引用必须指向同版本原型，例如 `../prototype/prototype_v1.1.html`。
- 新版 PRD 的版本记录表必须写清新增、修改、下线的功能点。
- 新功能必须先匹配 `nady-api-inventory.md` 的明确接口证据；证据不足时停止并向用户确认。

## v1.0 交付边界

- 本版本只产出 PRD、技术接入说明、接口迁移清单、原型和流程图。
- 本版本没有修改 Flutter 业务代码。
- 本版本没有启动本地服务；HTML 可直接打开预览，Mermaid 和 Tailwind 依赖 CDN 网络。
