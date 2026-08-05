# MVVM Architecture Guidelines

本项目后续开发统一采用 **轻量 MVVM + Repository/Service 分层**。

目标不是把项目做成过重的架构模板，而是让页面、状态、业务接口、底层能力各自稳定，避免页面里直接堆网络请求、缓存读写和复杂业务判断。

## 总体分层

推荐依赖方向：

```text
View -> ViewModel -> Repository -> Service/Manager -> External APIs
                    -> Model
```

只允许上层依赖下层，不允许反向依赖。

## 各层职责

### View

View 是页面和组件，只负责 UI 展示、用户输入、点击事件分发。

适合放在：

```text
lib/classes/<feature>/
lib/widgets/
```

View 可以做：

- 渲染页面布局、文本、图片、按钮和列表。
- 监听 ViewModel state 并展示 loading、error、empty、content。
- 把点击、输入、选择等事件转发给 ViewModel。
- 处理纯 UI 的临时状态，例如输入框 controller、焦点、动画 controller。

View 不允许做：

- 直接调用 Dio、HttpDioManager、AuthSession、IsarDB。
- 直接拼装接口参数和解析接口返回。
- 持有复杂业务流程，例如登录判断、保存用户、刷新用户信息。
- 在 build 方法里发起网络请求。

### ViewModel

ViewModel 负责页面状态和页面业务流程，是 View 和 Repository 之间的协调层。

优先使用 Riverpod：

```text
Notifier
AsyncNotifier
StateNotifier
FutureProvider
StateProvider
```

ViewModel 可以做：

- 管理页面状态，例如 loading、submitting、errorMessage、selectedCountry。
- 调用 Repository 完成业务动作。
- 把 Repository 返回的业务模型转换成 View 所需状态。
- 处理页面级流程，例如登录成功后跳转、失败后显示错误。

ViewModel 不允许做：

- 直接操作 Dio 请求细节。
- 直接拼接通用 headers、签名、x-auth-token。
- 直接依赖 Flutter BuildContext，除非是极少量页面生命周期适配。
- 写复杂 UI 布局。

### Repository

Repository 封装某个业务领域的接口和数据操作。

例如：

```text
AuthRepository
UserRepository
CountryRepository
DiaryRepository
UploadRepository
```

Repository 可以做：

- 调用 HttpDioManager 请求接口。
- 调用 AuthSession 保存或读取登录态。
- 调用 IsarDB 读取或保存本地业务数据。
- 解析接口返回，返回明确的 Model。
- 抛出或转换业务异常。

Repository 不允许做：

- 依赖 Widget、BuildContext、页面组件。
- 管理按钮 loading、弹窗、路由跳转等 UI 行为。
- 返回未经封装且无类型约束的复杂动态结构给 View。

### Service / Manager

Service 或 Manager 是底层基础能力。

当前项目已有：

```text
HttpDioManager  // 网络请求、签名、公共 header、日志
HttpApi         // 接口路径常量
AuthSession     // 登录态本地存储
AppDevice       // 设备信息、x-auth-token
IsarDB          // 本地数据库
UserManager     // 旧登录态兼容能力
```

Service / Manager 可以做：

- 提供平台能力、网络基础能力、存储基础能力。
- 不关心具体页面。
- 不主动操作 UI。

Service / Manager 不允许做：

- 调用页面 ViewModel。
- 做路由跳转和弹窗展示。
- 混入具体页面状态。

### Model

Model 是数据结构和轻量转换逻辑。

Model 可以做：

- fromJson / toJson。
- copyWith。
- enum 与服务端字段转换。
- 简单派生字段。

Model 不允许做：

- 发起网络请求。
- 访问本地存储。
- 持有 BuildContext。
- 处理页面交互。

## 推荐目录结构

新增功能优先按 feature 聚合：

```text
lib/classes/login/
  login_page.dart
  login_view_model.dart
  login_state.dart

lib/repositories/
  auth_repository.dart
  user_repository.dart
  country_repository.dart

lib/manager/
  http_dio_manager.dart
  http_api.dart
  auth_session.dart

lib/model/
  login_response.dart
  user_profile.dart
  country_info.dart
```

如果当前 feature 已经有历史目录，可以先沿用现有目录，但职责必须符合 MVVM。迁移时优先保证代码可读和低风险，不强制一次性搬目录。

## 当前项目落地规则

### 网络请求

- 所有 Nady 接口请求统一走 `HttpDioManager`。
- 接口 path 统一写在 `HttpApi`。
- 禁止页面直接创建 Dio。
- 禁止页面直接传公共 header、签名参数 `b`、时间戳 `v`。
- 禁止恢复旧的 `dioProvider / ApiClient / RequestInterceptors / RequestParamsCryptoInterceptor` 双网络层。

### 登录和用户

当前 `LoginProvider` 已经承担 Repository/Service 职责。后续开发中：

- 不再新增页面直接 `LoginProvider()` 的复杂调用链。
- 新增复杂登录/Profile 功能时，应优先抽出 ViewModel。
- 后续可逐步把 `LoginProvider` 重命名或迁移为 `AuthRepository`，但不要为了重命名做大范围无业务收益的重构。

### 页面状态

复杂页面必须有明确 state：

```dart
class LoginDetailState {
  const LoginDetailState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;
}
```

View 只根据 state 渲染，不直接推导复杂业务状态。

### 异常处理

- Repository 负责把接口异常转换成业务可理解的异常或失败结果。
- ViewModel 负责把异常转换成页面 state。
- View 负责展示错误，不负责判断错误来源。

## 新功能开发流程

1. 先确定 feature 属于哪个业务领域。
2. 如果有接口，先在 `HttpApi` 增加 path。
3. 在 Repository 中封装接口调用和数据解析。
4. 为复杂页面创建 `State + ViewModel`。
5. View 只绑定 state 和调用 ViewModel 方法。
6. 跑 `dart format` 和 `flutter analyze`。

## 禁止事项

- 禁止在 View 的 `build` 方法中直接请求网络。
- 禁止在 View 中直接读写 AuthSession、IsarDB。
- 禁止在 Model 中写业务请求逻辑。
- 禁止一个类同时承担 View、ViewModel、Repository 多层职责。
- 禁止新增第二套网络请求框架。
- 禁止为了架构纯粹性做大范围无关重构。

## 允许例外

以下情况可以不单独创建 ViewModel：

- 纯静态展示页。
- 很小的无业务组件。
- 只读本地常量数据的简单页面。

但一旦页面包含网络请求、提交动作、多个 loading/error 状态或跨页面业务流程，就必须使用 ViewModel。

## 代码评审检查清单

提交前确认：

- View 没有直接调用网络、数据库、登录态存储。
- ViewModel 没有写 UI 布局。
- Repository 没有依赖 BuildContext。
- API path 在 `HttpApi` 中统一维护。
- 网络请求走 `HttpDioManager`。
- state 能表达 loading、error、empty、success。
- `flutter analyze` 通过。
