/// 登录功能测试说明
///
/// 本文件用于说明 LoginDetailPage 中实现的登录功能
///
/// 实现的功能：
/// 1. 使用 ApiPath.login 接口进行登录请求
/// 2. 使用 ApiClient 的 dio 实例发送请求
/// 3. 自动获取设备信息（使用 AppDevice 类）
/// 4. 密码使用 SHA-512 加密
/// 5. 包含完整的设备参数：
///    - deviceId: 设备唯一标识
///    - app: 应用名称
///    - appVersion: 应用版本号
///    - appVersionCode: 应用构建号
///    - channel: 渠道（DEV）
///    - systemLanguage: 系统语言
///    - appLanguage: 应用语言
///    - model: 设备型号
///    - os: 操作系统
///    - osVersion: 系统版本
///    - deviceBrand: 设备品牌
///    - appsflyerUID: 设备指纹
///
/// 登录参数示例：
/// ```json
/// {
///   "code": "13104889693",
///   "loginType": 5,
///   "passwd": "60e7797b545a573bba5842633ee5a828...",
///   "smsCode": "",
///   "areaCode": "966",
///   "countryCode": "us",
///   "fbLimited": false,
///   "deviceId": "e7e8bebfcc5fc843bf394de79c0f1cad...",
///   "app": "Nady",
///   "appVersion": "1.14.1",
///   "appVersionCode": 40,
///   "channel": "DEV",
///   "systemLanguage": "en-US",
///   "appLanguage": "en",
///   "isp": "",
///   "model": "sdk_gphone64_arm64",
///   "os": "android",
///   "osVersion": "|REL|13193326|0|16|36|2025-03-05",
///   "deviceBrand": "goldfish_arm64",
///   "appsflyerUID": "1769519939034-2793075034332800194"
/// }
/// ```
///
/// 响应处理：
/// - 成功时（code == 200）：显示成功消息，保存 token，跳转到首页
/// - 失败时：显示错误消息
/// - 异常时：显示错误提示
///
/// 使用方式：
/// 1. 输入账号（邮箱或手机号）
/// 2. 输入密码
/// 3. 点击 Login 按钮
/// 4. 等待响应
void main() {
  print('登录功能已实现，详见 LoginDetailPage');
}

