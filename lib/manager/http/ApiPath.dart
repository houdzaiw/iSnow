class ApiPath {
  /// ==================== 国家相关 ====================
  /// 获取默认国家码
  static const defaultCountry = '/country-list/default-country';

  /// 热门国家
  static const hotCountry = '/country-list/hot';

  /// 支持的国家列表
  static const supportedCountry = '/country-list/supported';

  /// ==================== 用户相关 ====================
  /// 是否已存在用户
  static const hasUser = '/api/user/hasUser';

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

  /// 礼物
  static const sendGift = '/oauth2/logout';
}
