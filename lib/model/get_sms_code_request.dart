// filepath: /Users/admin/Documents/project/isnow/lib/model/get_sms_code_request.dart

import '../classes/oauth/provider/login_provider.dart';
enum GetSMSType {
  none,
  sms,
  whatsapp,
}

enum GetSMSPurpose {
  register,
  forgetPassword,
  accountBinding,
  accountChangeBinding,
  verifyBinding,
}

extension GetSMSPurposeExt on GetSMSPurpose {
  int get value {
    switch (this) {
      case GetSMSPurpose.register:
        return 1;
      case GetSMSPurpose.forgetPassword:
        return 2;
      case GetSMSPurpose.accountBinding:
        return 3;
      case GetSMSPurpose.accountChangeBinding:
        return 4;
      case GetSMSPurpose.verifyBinding:
        return 5;
    }
  }

  static GetSMSPurpose fromValue(int value) {
    switch (value) {
      case 1:
        return GetSMSPurpose.register;
      case 2:
        return GetSMSPurpose.forgetPassword;
      case 3:
        return GetSMSPurpose.accountBinding;
      case 4:
        return GetSMSPurpose.accountChangeBinding;
      case 5:
        return GetSMSPurpose.verifyBinding;
      default:
        throw ArgumentError('Invalid GetSMSPurpose value: $value');
    }
  }
}

class GetSMSCodeRequest {
  final String phone;
  final String areaCode;
  final GetSMSPurpose purpose;
  final GetSMSType type;
  final String language;

  GetSMSCodeRequest({
    required this.phone,
    required this.areaCode,
    required this.purpose,
    required this.type,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'areaCode': areaCode,
      'purpose': purpose.value,
      'type': type.index,
      'language': language,
    };
  }

  @override
  String toString() {
    return 'GetSMSCodeRequest(phone: $phone, areaCode: $areaCode, purpose: $purpose, type: $type, language: $language)';
  }
}

