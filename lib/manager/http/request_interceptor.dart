import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/lib/logger.dart';
import 'package:project/manager/auth_session.dart';

import '../server_response.dart';
import 'api_client.dart';

class RequestInterceptors extends Interceptor {
  static const String _sendGiftPath = '/api/gift/sendGift';

  final Ref ref;
  final bool? isBrowser;

  RequestInterceptors({required this.ref, this.isBrowser}) : super();

  bool isHttps(String url) {
    return url.startsWith('https://');
  }

  bool isHttp(String url) {
    return url.startsWith('http://');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // if (!ref.read(hasNetworkProvider)) {
    //   //SmartDialog.dismiss(status: SmartStatus.loading);
    //   Logger.error("Network abnormality, please try again later");
    //   handler.reject(DioException(
    //     requestOptions: options,
    //     error: 'Network abnormality, please try again later',
    //   ));
    //   //SmartDialog.showToast("Network abnormality, please try again later");
    //   return;
    // }

    // if (NDSManager().canReplace()) {
    //   Logger.infoWrite("/// 替换前域名: ${options.baseUrl}");
    //   if (isHttps(options.baseUrl)) {
    //     options.baseUrl = "https://${NDSManager().hostIp}:443/simi";
    //   }
    //
    //   if (isHttp(options.baseUrl)) {
    //     options.baseUrl = "http://${NDSManager().hostIp}:443/simi";
    //   }
    //
    //   Logger.infoWrite("/// 替换后ip: ${options.baseUrl}");
    // }

    // bool http = await DebugConfigManager().http;
    // if (http) {
    //   options.baseUrl = options.baseUrl.replaceAll('https://', 'http://');
    // }

    final deviceData = AppDevice();
    final language = deviceData.appLanguage;
    final uid = await AuthSession.instance.uid();
    final token = await AuthSession.instance.token();

    if (uid != null && token != null) {
      options.headers['pub-uid'] = uid;
      options.headers['oauth-token'] = token;
    }
    options.headers['systemLanguage'] = deviceData.systemLanguage;
    options.headers['timeZone'] = deviceData.timeZone;
    options.headers['storeCode'] = deviceData.countryCode.isEmpty
        ? 'CN'
        : deviceData.countryCode;
    options.headers['appVersion'] = deviceData.appVersion;

    options.headers['appLanguage'] = language;

    // Await the async _toString() call
    final xAuthToken = await _toString();
    options.headers['x-auth-token'] = xAuthToken;

    options.headers['startTime'] = DateTime.now().millisecondsSinceEpoch;
    Logger.info("""
              ${options.baseUrl}${options.path}
              🦊请求发起🦊 ${options.method}: ${options.path}
              header: ${jsonEncode(options.headers)}
              params: ${"POST" == options.method ? options.data : options.queryParameters}
              """);
    return super.onRequest(options, handler);
  }

  Future<String> _toString() async {
    return AppDevice().generateAuthToken();
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        try {
          final reply = BaseServerResponse.fromJson(
            response.data as Map<String, dynamic>,
          );

          if (kDebugMode) {
            Logger.info(
              """
              ${response.requestOptions.baseUrl}${response.requestOptions.path}
              请求域名 ${response.requestOptions.baseUrl}
              🦊请求结果🦊 ${response.requestOptions.method}: ${response.requestOptions.path}
              header: ${jsonEncode(response.requestOptions.headers)}
              params: ${"POST" == response.requestOptions.method ? response.requestOptions.data : response.requestOptions.queryParameters}
              response: ${const JsonEncoder.withIndent('').convert(response.data)}
              """,
              // traceId: ${response.data["traceId"] ?? ""}
              //              response: ${const JsonEncoder.withIndent('').convert(response.data)}
            );
          }
          if (isBrowser == true) {
            if (reply.code == ServiceStatusCode.successCode) {
              return super.onResponse(response, handler);
            } else {
              handler.reject(
                DioException(
                  response: response,
                  requestOptions: response.requestOptions,
                  message: reply.message,
                ),
                false,
              );
            }
            return;
          }

          /// 请求接口异常报错 记录
          if (reply.code != ServiceStatusCode.successCode) {
            Logger.error(
              "请求报错接口1: ${response.requestOptions.baseUrl}${response.requestOptions.path} 错误码: ${reply.code} 错误信息: ${reply.message}",
            );

            // 计算请求耗时
            _infoRequestDurationTime(response.requestOptions);
          }

          if (reply.code == ServiceStatusCode.successCode) {
            return super.onResponse(response, handler);
          } else if (ServiceStatusCode.loginRestrictionCodes.contains(
            reply.code,
          )) {
            // _onShowLoginRestrictionDialog(reply);
          } else if (reply.code == ServiceStatusCode.insufficientCoinBalanc) {
            if (response.realUri.toString().contains(_sendGiftPath)) {
              return super.onResponse(response, handler);
            } else {
              // showToast(reply.message ?? "");
              if (response.realUri.toString().contains(
                "/api/wheel/createLuckyWheel",
              )) {
                //SmartDialog.dismiss(status: SmartStatus.loading);
              }
              if (response.realUri.toString().contains(
                "/api/wheel/joinLuckyWheel",
              )) {
                //SmartDialog.dismiss(status: SmartStatus.loading);
              }
              //金币不足 发送弹幕
              if (response.realUri.toString().contains(
                "api/bullet/sendBullet",
              )) {
                //SmartDialog.dismiss(status: SmartStatus.loading);
              }
              if (response.realUri.toString().contains("api/vip/buy")) {
                //SmartDialog.dismiss();
                //SmartDialog.dismiss(status: SmartStatus.loading);
              }
              //购买金币不足
              // if (response.realUri.toString().contains("api/shop/prop/purchaseOnSaleProp") ||
              //     response.realUri.path.contains(Apis.aristocracyBuy)) {
              //SmartDialog.dismiss(status: SmartStatus.loading);
              // NadyRechargeCoinsAlter.show();
              // showBottomToast("Insufficient coins");
              // }
              // if (response.realUri.path.contains(Apis.aristocracyBuy)) {
              //SmartDialog.dismiss(status: SmartStatus.loading);
              // }
              // if (response.realUri.toString().contains(Apis.luckyBagSend) ||
              //     response.realUri.path.contains(Apis.luckyBagSend)) {
              //SmartDialog.dismiss(status: SmartStatus.loading);
              // NadyRechargeCoinsAlter.show();
              // showBottomToast("Insufficient coins");
              // }
            }
          } else if (reply.code ==
              ServiceStatusCode.restrictionsOnRegistration) {
            //SmartDialog.dismiss(status: SmartStatus.loading);
            // NadyMessagePopUp.show(
            //     title: "Frequent operation",
            //     message: reply.message,
            //     axis: NadyMessagePopUpButtonAxis.one);
          } else if (reply.code == ServiceStatusCode.shutDownCode) {
            //SmartDialog.dismiss(status: SmartStatus.loading);

            // String messageStr = reply.message ?? "";
            // UserShutDownModel shutDownModel = UserShutDownModel.fromJson(jsonDecode(messageStr));
            if (response.requestOptions.path == "/api/room/inRoom") {
              //房间被封禁
              // NadyMessagePopUp.show(
              //     title: "This user's room was banned",
              //     message: "${"Ban time: {}".tr(args: [
              //           "${shutDownModel.blackSTime.formatString()} - ${shutDownModel.blackETime.formatString()}"
              //         ])} \n ${"Ban reason: {}".tr(
              //       args: [shutDownModel.blackRemark],
              //     )}",
              //     axis: NadyMessagePopUpButtonAxis.one);
              return;
            }

            // String shutDownTypeStr = "user";
            // if (shutDownModel.blackType == 2) {
            //   shutDownTypeStr = "device";
            // } else if (shutDownModel.blackType == 3) {
            //   shutDownTypeStr = "ip";
            // }
            // final userInfo = ref.read(myUserInfoProvider).value?.userBaseInfo;
            // var userNo = "${userInfo?.userNo ?? ''}";
            // NadyMessagePopUp.show(
            //     title: "This {} was banned".tr(args: [shutDownTypeStr]),
            //     messageWidget: Column(children: [
            //       NadyTextWidget(
            //         "${"Ban time: {}".tr(args: [
            //               "${shutDownModel.blackSTime.formatString()} - ${shutDownModel.blackETime.formatString()}"
            //             ])} \n ${"Ban reason: {}".tr(
            //           args: [shutDownModel.blackRemark],
            //         )}",
            //         size: 14,
            //         weight: FontWeight.w400,
            //         color: Color(0xFF212121),
            //         textAlign: TextAlign.center,
            //         maxLines: 1000,
            //       ),
            //       if (shutDownModel.blackType == 1 && userNo.isNotEmpty)
            //         Text("data")
            //     ]),
            //     showCloseButton: shutDownModel.blackType == 1,
            //     confirmWidget: const NadyCustomerServiceBtn(),
            //     backDismiss: false,
            //     axis: shutDownModel.blackType == 1
            //         ? NadyMessagePopUpButtonAxis.one
            //         : NadyMessagePopUpButtonAxis.none);
          } else if (reply.code == 12101 ||
              reply.code == 12102 ||
              reply.code == 12103 ||
              reply.code == 12104 ||
              reply.code == 12105 ||
              reply.code == 12106 ||
              reply.code == 12107 ||
              reply.code == 12108 ||
              reply.code == 12109 ||
              reply.code == 12110 ||
              reply.code == 12111) {
            //SmartDialog.dismiss(status: SmartStatus.loading);
            // NadyMessagePopUp.show(
            //     title: "${reply.message}",
            //     axis: NadyMessagePopUpButtonAxis.one);
          } else if (reply.code == 4054 ||
              reply.code == 10203 ||
              reply.code == 4062) {
            return super.onResponse(response, handler);
          } else {
            Logger.error(
              'server response is biz error code error : ${response.data}',
            );
            Logger.error(
              '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            );
            //SmartDialog.dismiss(status: SmartStatus.loading);
            // showCenterToast('${reply.message}');
            handler.reject(
              DioException(
                response: response,
                requestOptions: response.requestOptions,
                message: reply.message,
              ),
              false,
            );
          }
        } catch (e, stack) {
          Logger.error('server response format error', e, stack);
          handler.reject(
            DioException(
              response: response,
              requestOptions: response.requestOptions,
              message: 'server response format error',
              error: e,
            ),
            false,
          );
        }
      } else {
        Logger.error('server response is not map : ${response.data}');
        handler.reject(
          DioException(
            response: response,
            requestOptions: response.requestOptions,
            message: 'server response format error',
          ),
          false,
        );
      }
    } else {
      switch (response.statusCode) {
        case 401:
          Logger.warning('logoff and need to login');
          break;
        case 403:
          Logger.warning('logout and need to login');
          break;
        default:
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
            ),
            false,
          );
          break;
      }
    }
  }

  //获取时间差
  void _infoRequestDurationTime(RequestOptions requestOptions) {
    if (requestOptions.headers.containsKey("startTime")) {
      final startTime = requestOptions.headers['startTime'] as int?;
      if (startTime != null) {
        final endTime = DateTime.now().millisecondsSinceEpoch;
        int duration = endTime - startTime;
        Logger.error(
          "请求接口耗时: ${requestOptions.baseUrl}${requestOptions.path} 请求耗时: ${duration}ms",
        );
      }
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Logger.error(err.requestOptions.baseUrl + err.requestOptions.path);
    Logger.error(
      '请求报错接口2: ${err.requestOptions.baseUrl}${err.requestOptions.path}',
    );
    _infoRequestDurationTime(err.requestOptions);
    //SmartDialog.dismiss(status: SmartStatus.loading);
    Logger.infoWrite("获取到了错误 err.message2： ${err.error.toString()}");
    if (getOpenHttpNDSResult(err)) {
      // NDSManager().setLocalNeedEnable(true);
      // NDSManager().setIpWithHost(host: err.requestOptions.baseUrl);
    }
    super.onError(err, handler);
  }

  bool getOpenHttpNDSResult(DioException err) {
    String messageStr =
        "${err.message ?? ""} ${err.error.toString()}"
        "${err.toString()}";

    bool result = false;
    if (messageStr.isNotEmpty) {
      if (messageStr.contains("ERR_NAME_NOT_RESOLVED") ||
          messageStr.contains("ERR_INTERNET_DISCONNECTED") ||
          messageStr.contains("ERR_CONNECTION_ABORTED") ||
          messageStr.contains("ERR_NETWORK_CHANGED") ||
          messageStr.contains("ERR_ADDRESS_UNREACHABLE") ||
          messageStr.contains("ERR_CONNECTION_TIMED_OUT") ||
          messageStr.contains(
            "This indicates an error which most likely cannot be solved by the library",
          )) {
        Logger.infoWrite("/// 命中 获取到了错误  err.message： $messageStr");
        result = true;
      }
    }

    return result;
  }
}
