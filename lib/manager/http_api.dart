class HttpApi {
  /// ==================== 国家相关 ====================
  /// 按国家 ISO code 查询拨号码
  /// Travel test 路由目录未提供该接口的混淆 Token，暂保留原路径以便明确暴露配置缺口。
  static const queryCountryCode = '/api/user/country/query/code';

  /// 获取默认国家码
  static const defaultCountry = 'sGCLe_lLqtYUC7byaEqQjaSm_RPTvHkF5ExH4A2x62Y';

  /// 热门国家
  static const hotCountry = 'OrDOQrssWvnyuMfujAmhaeMGsPFVFtybo38i7nycBu0';

  /// 支持的国家列表
  static const supportedCountry = 'Xx3O-CwPPM3GoVUTScCAmDyQAJrfiy6qahaVkUznYQc';

  /// ==================== 用户相关 ====================
  /// 是否已存在用户
  static const hasUser = 'cJpmmSkf4QW6w9sbNhG3NLYTiVJQyKfv6hL_xEDdp6M';

  /// 注册完善资料
  static const completeUser = 'tCFUs7JGzBanO-k988k55sZvauRvl_fIgIlS8XSEZI4';

  /// 获取我的用户信息
  static const myUserInfo = 'QPCuM9mWXOD_fwauyLbMwQi8oL2Iur5Lvl-9Z4xw-mc';

  /// 更新用户资料
  static const modifyUser = 'wMkeNhzxhcgss54wfqYULLha0KTsZnoiaYHJizFfOAw';

  /// ==================== 认证 / 登录 ====================
  /// 登录
  static const login = 'M3sLd4tiv1SoF8_xW1kTmyLqyNQ69pZ29CrRwR0NANU';

  /// 发送验证码
  static const sendSms = '9T8jKJFkK_jrnw4k-NDRiTO3mEmDf9UlaKYQrg5CNZc';

  /// 校验验证码
  static const verifyCode = 'VXEVtcW8rLr9RFhuyZ09v8wgoPX-l5t3ZO2HwS_ln3c';

  /// 设置密码
  static const setPassword = 'i4eKcze5fatBpqeaut4tb4OViqM-lrQlDSVdLHh0vDA';

  /// 登出
  static const logout = 'WDvFmqZRYw7O76QRJkiH-FZOlKykvYbiluTzwXpJvSc';

  /// 注销账号
  static const logoff = 'whmhSjKBjr3owpz4oCgNb0wCPjTWBU3qvpft1xs2Xpg';

  /// 获取头像上传参数
  static const uploadParam = 'DbFjez2-t0ihTBX0DNPnaXVkGyV2ja8AW974P9RpZE0';
}
