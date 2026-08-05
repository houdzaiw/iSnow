class HttpApi {
  /// ==================== 国家相关 ====================
  /// 按国家 ISO code 查询拨号码
  static const queryCountryCode = '/api/user/country/query/code';

  /// 获取默认国家码
  static const defaultCountry = '/country-list/default-country';

  /// 热门国家
  static const hotCountry = '/country-list/hot';

  /// 支持的国家列表
  static const supportedCountry = '/country-list/supported';

  /// ==================== 用户相关 ====================
  /// 是否已存在用户
  static const hasUser = '/api/user/hasUser';

  /// 注册完善资料
  static const completeUser = '/api/user/complete';

  /// 获取我的用户信息
  static const myUserInfo = '/api/user/mine';

  /// 更新用户资料
  static const modifyUser = '/api/user/modifyUser';

  /// ==================== 首页 / 房间 ====================
  /// 首页推荐房间列表
  static const homeRecommendRoom = '/api/home/room/recommend';

  /// 派对列表
  static const partyList = '/api/room/party/list';

  /// ==================== 认证 / 登录 ====================
  /// 登录
  static const login = '/oauth2/login';

  /// 发送验证码
  static const sendSms = '/oauth2/sendSms';

  /// 校验验证码
  static const verifyCode = '/oauth2/verify/code';

  /// 设置密码
  static const setPassword = '/oauth2/setPassword';

  /// 登出
  static const logout = '/oauth2/logout';

  /// 注销账号
  static const logoff = '/api/user/logoff';

  /// 获取头像上传参数
  static const uploadParam = '/api/resource/header-upload-param';
}
