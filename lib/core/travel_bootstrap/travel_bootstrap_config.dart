import 'travel_bootstrap_exception.dart';

/// iSnow 当前默认使用的 Travel test 环境公开材料。
///
/// 该配置只包含 Bootstrap 所需的公开材料；运行时会话密钥、业务密钥和登录
/// 凭据只保存在内存中。服务端更新材料时通过 dart-define 覆盖这些默认值。
final class TravelBootstrapConfig {
  const TravelBootstrapConfig._();

  static const environment = String.fromEnvironment(
    'travel.environment',
    defaultValue: 'test',
  );
  static const bootstrapUrl = String.fromEnvironment(
    'travel.bootstrapUrl',
    defaultValue: 'https://www.lvyoutest.xyz/lvy/api/x9',
  );
  static const bootstrapAadPath = String.fromEnvironment(
    'travel.bootstrapAadPath',
    defaultValue: '/api/x9',
  );
  static const bootstrapKid = String.fromEnvironment(
    'travel.bootstrapKid',
    defaultValue: 'copy-47f353d8c01a499699c47f3feaf145a6',
  );
  static const channel = String.fromEnvironment(
    'travel.channel',
    defaultValue: 'lvyou',
  );
  static const allowInsecureHttp = bool.fromEnvironment(
    'travel.allowInsecureHttp',
    defaultValue: false,
  );

  static const bootstrapPublicKeyPem = String.fromEnvironment(
    'travel.bootstrapPublicKeyPem',
    defaultValue: '''-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAm2iw7dHgsWn4B+3ojuwS
qw01Gp0GabES9MVu4Seq6d1Iz4NLLyAWhZcb/NhqP50rW9bKs3hULwLbbDcwac5U
5KnwCZ6xQZp3qdHIAc7mb66trbZ1mRf0n7VPjZN8xd+EkhpS0dHGAVWGkKncpg4y
juyJDnNBuK4ySTfXxChIr92C4ZC8nfLl5siRl/uvZJqDJCoZCPnRdFBheYuJkNSp
X+0NcoBmfVkatUbu/ymm2VIsbH7T3eYNwKpFOF6ax7eosPzOp6V3kNRIMhltKCs2
aqpgH3JR1yP1MIP/Hzk8JiiG753YH/yypXPzoziCptnRBn++aGbNjFak3limNdZy
MBPxBBrx8Jq9wQJt/196F4+Ese+qkklPwAO7yJARLH/UNcsYMaAVV/L0bwhxsk3U
4RVOS20ekGN4GhzBntGYhvDy8MEfCwuA1inp8QgMCc1OXTnK+il4kLVDHliFvXH3
Om8s43iBe+Fo7A1ys/IBaG/2iV8Vf3sn3etmaoOm6GnpAgMBAAE=
-----END PUBLIC KEY-----''',
  );

  static const routeTokens = <String, String>{
    'country.default': 'sGCLe_lLqtYUC7byaEqQjaSm_RPTvHkF5ExH4A2x62Y',
    'country.hot': 'OrDOQrssWvnyuMfujAmhaeMGsPFVFtybo38i7nycBu0',
    'country.supported': 'Xx3O-CwPPM3GoVUTScCAmDyQAJrfiy6qahaVkUznYQc',
    'user.hasUser': 'cJpmmSkf4QW6w9sbNhG3NLYTiVJQyKfv6hL_xEDdp6M',
    'oauth2.sendSms': '9T8jKJFkK_jrnw4k-NDRiTO3mEmDf9UlaKYQrg5CNZc',
    'oauth2.login': 'M3sLd4tiv1SoF8_xW1kTmyLqyNQ69pZ29CrRwR0NANU',
    'oauth2.setPassword': 'i4eKcze5fatBpqeaut4tb4OViqM-lrQlDSVdLHh0vDA',
    'oauth2.verifyCode': 'VXEVtcW8rLr9RFhuyZ09v8wgoPX-l5t3ZO2HwS_ln3c',
    'oauth2.resetPassword': 'UBJYXgZVltNP2FFVX3ZxWSIKtoNM-YH2N1XncjLXvuA',
    'client.init': 'LrHPwAAR_ltmgt9BF-YwNpw_9jjaEaRKVSk26boEAe0',
    'user.complete': 'tCFUs7JGzBanO-k988k55sZvauRvl_fIgIlS8XSEZI4',
    'resource.function2': 'FIWDO_6VT3Ozy-3vlTd1iOBCUtjic1tp8iRGnoicGp0',
    'user.mine': 'QPCuM9mWXOD_fwauyLbMwQi8oL2Iur5Lvl-9Z4xw-mc',
    'user.modify': 'wMkeNhzxhcgss54wfqYULLha0KTsZnoiaYHJizFfOAw',
    'resource.headerUploadParam': 'DbFjez2-t0ihTBX0DNPnaXVkGyV2ja8AW974P9RpZE0',
    'oauth2.logout': 'WDvFmqZRYw7O76QRJkiH-FZOlKykvYbiluTzwXpJvSc',
    'user.logoff': 'whmhSjKBjr3owpz4oCgNb0wCPjTWBU3qvpft1xs2Xpg',
  };

  static String tokenFor(String name) {
    final token = routeTokens[name];
    if (token == null || token.isEmpty) {
      throw TravelBootstrapException('Missing Travel route token: $name');
    }
    return token;
  }
}
