enum AppEnv {
  dev("https://www", "socket://im.xxx.net", "https://res.xxx.net", false),
  product("https://www", "socket://im.xxxx.net", "https://res.xxxxx.net", true);

  final String baseUrl;
  final String socketHost;
  final String h5Url;
  final bool isLocal;
  const AppEnv(this.baseUrl, this.socketHost, this.h5Url, this.isLocal);
}

enum ErrorCode {
  normal(code:0),
  tokenInvalid(code:1100103),
  tokenEmpty(code:10010301),
  tokenFormatError(code:10010302),
  tokenTimeOut(code:10010303),
  deviceLogin(code:10010304),
  blockUser(code:10010003);
  final int code;
  const ErrorCode({required this.code});
}

enum OauthType {
  google(1), facebook(2), twitter(3), apple(4), smsCode(5), password(6), register(7), smsRegister(8);
  final int value;
  const OauthType(this.value);
}