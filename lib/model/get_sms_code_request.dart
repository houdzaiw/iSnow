// filepath: /Users/admin/Documents/project/isnow/lib/model/get_sms_code_request.dart

import '../classes/oauth/provider/login_provider.dart';

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

