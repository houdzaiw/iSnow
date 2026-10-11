enum AppEnv {
  dev(
    "http://simi2.w1.luyouxia.net/simi",
    "https://www.simijoy.com",
    "https://analytics-preview.habilive.net",
    "https://www.simijoy.com/h5/wallet/index.html",
    false,
    agoraAppId: 'd5167c704aa4448c867a77f5989fdc66',
  ),
  qa(
    "https://www.simijoy.com/simi",
    "https://www.simijoy.com",
    "https://analytics-preview.habilive.net",
    "https://www.simijoy.com/h5/wallet/index.html",
    false,
    agoraAppId: 'd5167c704aa4448c867a77f5989fdc66',
  ),
  product(
    "https://www.simisoul.com/simi",
    "https://www.simisoul.com",
    "https://analytics.habilive.net",
    "https://www.simisoul.com/h5/wallet/index.html",
    true,
    agoraAppId: 'f4dffe3fe2564e50b4cd897a9aa9a781',
  );

  final String baseUrl;
  final String socketHost;
  final String h5Url;
  final String h5WalletUrl;
  final bool isLocal;
  final String _agoraAppId;

  String get agoraAppId {
    const override = String.fromEnvironment('AGORA_APPID');
    return override.isNotEmpty ? override : _agoraAppId;
  }

  const AppEnv(
    this.baseUrl,
    this.socketHost,
    this.h5Url,
    this.h5WalletUrl,
    this.isLocal, {
    required String agoraAppId,
  }) : _agoraAppId = agoraAppId;
}

enum ErrorCode {
  normal(code: 0),
  tokenInvalid(code: 1100103),
  tokenEmpty(code: 10010301),
  tokenFormatError(code: 10010302),
  tokenTimeOut(code: 10010303),
  deviceLogin(code: 10010304),
  blockUser(code: 10010003);

  final int code;
  const ErrorCode({required this.code});
}

enum OauthType {
  google(1),
  facebook(2),
  twitter(3),
  apple(4),
  smsCode(5),
  password(6),
  register(7),
  smsRegister(8);

  final int value;
  const OauthType(this.value);
}
