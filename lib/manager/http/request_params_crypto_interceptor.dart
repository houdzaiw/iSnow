
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:project/ext/ex_string.dart';


class RequestParamsCryptoInterceptor extends Interceptor {
  int? serverTime;
  int? lastResponseTime;
  final timeStampName = "v";
  final signParamName = "b";

  final Ref ref;
  final bool? isBrowser;

  RequestParamsCryptoInterceptor({required this.ref, this.isBrowser}) : super();


  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    Map<String, dynamic> requestParams = {};
    if(options.method == "GET") {
      requestParams.addAll(options.queryParameters);
    } else {
      if(options.data is FormData) {
        for (var value in (options.data as FormData).fields) {
          requestParams[value.key] = value.value;
        }
      } else {
        if(options.data is Map<String, dynamic>) {
          requestParams.addAll(options.data as Map<String, dynamic>);
        } else {
          try {
            requestParams.addAll(options.data.toJson() as Map<String, dynamic>);
          } catch(e, s) {
            // Logger.talker.error("json error 11", e, s);
            print("json error 11: $e \n $s");
          }
        }
      }
    }

    // 添加时间
    dynamic timeStamp = serverTime ?? getCurrentTime();
    if(lastResponseTime != null) {
      // 上一次返回时间计算
      timeStamp += (DateTime.now().millisecondsSinceEpoch - (lastResponseTime ?? 0));
    }
    timeStamp = timeStamp.toString();
    requestParams[timeStampName] = timeStamp;
    // final apiSecretKey = ref.read(envProvider).apiSecretKey;
    final apiSecretKey = "T4&pQ@9n";
    // 生成签名
    String sign = generateSign(requestParams, apiSecretKey);

    options.headers.addAll({"b": sign, "v": timeStamp});

    // next
    handler.next(options);
  }


  /// Called when the response is about to be resolved.
  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    lastResponseTime = DateTime.now().millisecondsSinceEpoch;
    serverTime = response.headers.value(timeStampName)?.toInt ?? getCurrentTime();
    handler.next(response);
  }

  int getCurrentTime() {
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }


  String generateSign(Map<String, dynamic> requestParam, String secret) {
    // 1. 添加密钥
    requestParam["secret"] = secret;

    // 2. sort params
    var sortedKeys = requestParam.keys.toList()..sort();
    StringBuffer stringBuffer = StringBuffer();

    // 3. 拼接参数
    for(var index = 0; index < sortedKeys.length; index ++) {
      stringBuffer.write('${sortedKeys[index]}=${requestParam[sortedKeys[index]]}');
      if(sortedKeys.length - 1 != index ) {
        stringBuffer.write("&");
      }
    }


    // var newStringBuffer2 = """
    // avatar=https://simisoul.xyz/prod/089d7273928ce07afbbadba5c17e0aadc96dd1be.jpg&roomDesc=🫶🏻RESPECT EACH OTHER 🫶🏻
    // NO BULLYING 📌
    // FRIENDLY 📌
    //
    // &roomId=1986323783696117761&roomLock=false&roomPasswd=&secret=ji18^##710*(%Mhoaeqwe&title=THE INFINITY AGENCY❤️&v=1762415153734
    // """;
    // var result = newStringBuffer2.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    // print("原始：${newStringBuffer2}");
    // print("替换：$result");
    // print("结果：${md5.convert(utf8.encode(result)).toString()}");
    //
    //
    //
    // var newStringBuffer3 = """
    // avatar=https://simisoul.xyz/dev/7bd4f48608c45cc1e5f2fbe91e1572cbff33d8e4.jpg&roomDesc=لكل إنسان صديق فكن صديق&roomId=1952961342723891201&roomLock=false&roomPasswd=&secret=T4&pQ@9n&title=💔 SAKIL  ... Vai 🫶&v=1762418189026
    // """;
    // var result3 = newStringBuffer3.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    // print("原始：${newStringBuffer3}");
    // print("替换：$result3");
    // print("结果：${md5.convert(utf8.encode(result3)).toString()}");

    var result5 = stringBuffer.toString().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    // 4. 计算md5
    return md5.convert(utf8.encode(result5)).toString();
  }
}
