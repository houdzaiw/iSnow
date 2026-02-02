import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/lib/crypt_util.dart';
import 'package:project/manager/http/api_client.dart';
import 'package:project/manager/http/dio_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../manager/http/api_path.dart';

// final loginRepositoryProvider = Provider<LoginRepository>((ref) {
//   final dio = ref.read(dioProvider);
//   final apiClient = ApiClient(dio: dio);
//   return LoginRepository(apiClient);
// });
//
// class LoginRepository {
//   final ApiClient _apiClient;
//
//   LoginRepository(this._apiClient);
//
//   Future<void> login(Map<String, dynamic> params) async {
//     try {
//       final response = await _apiClient.dio.post(ApiPath.login, data: params);
//       if (response.statusCode == 200) {
//         // Handle successful login
//         print('Login successful: ${response.data}');
//       } else {
//         // Handle error response
//         print('Login failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       // Handle exceptions
//       print('Login error: $e');
//     }
//   }
// }

class LoginDetailPage extends HookConsumerWidget {
  const LoginDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: "13104889693");
    final passwordController = useTextEditingController(text: "123456");
    final isLoading = useState(false);

    Future<void> getDefaultCountry() async {
      // 获取 Dio 实例
      final dio = ref.read(dioProvider);

      final apiClient = ApiClient(dio: dio);

      print("baseUrl====${ApiPath.baseUrl}");
      // 发送登录请求
      final response = await apiClient.dio.get(
        ApiPath.defaultCountry,
        data: {},
      );
      if (response.statusCode == 200) {
        final data = response.data;
      } else {

      }
    }
    Future<void> handleLogin() async {
      final account = emailController.text.trim();
      final password = passwordController.text.trim();

      // 验证输入
      if (account.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email or phone')),
        );
        return;
      }

      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        return;
      }

      // 开始加载
      isLoading.value = true;

      try {
        // 获取设备信息
        final appDevice = AppDevice();

        // 构建登录参数
        final params = {
          "code": account,
          "loginType": 5,
          "passwd": CryptUtil.encrypt(password),
          "smsCode": "",
          "areaCode": "966",
          "countryCode": "us",
          "fbLimited": false,
          "deviceId": appDevice.deviceId,
          "app": appDevice.appName,
          "appVersion": appDevice.appVersion,
          "appVersionCode": int.tryParse(appDevice.appVersionCode) ?? 1,
          "channel": "DEV",
          "systemLanguage": appDevice.systemLanguage,
          "appLanguage": appDevice.appLanguage,
          "isp": "",
          "model": appDevice.model,
          "os": appDevice.os,
          "osVersion": appDevice.osVersion,
          "deviceBrand": appDevice.deviceBrand,
          "appsflyerUID": appDevice.fingerprint,
        };
        print("params====$params");
        // 获取 Dio 实例
        final dio = ref.read(dioProvider);

        // 创建 ApiClient
        final apiClient = ApiClient(dio: dio);

        print("baseUrl====${ApiPath.baseUrl}");
        // 发送登录请求
        final response = await apiClient.dio.post(
          ApiPath.login,
          data: params,
        );

        if (!context.mounted) return;

        // 处理响应
        if (response.statusCode == 200) {
          final data = response.data;

          if (data['code'] == ServiceStatusCode.successCode) {
            // 登录成功
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful!')),
            );

            // TODO: 保存 token 和用户信息到本地存储
            final token = data['data']?['token'];
            print('Login Token: $token');

            // 跳转到首页
            if (context.mounted) {
              context.go('/');
            }
          } else {
            // 登录失败
            final message = data['message'] ?? 'Login failed';
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server error: ${response.statusCode}')),
            );
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      backgroundColor: const Color(0xFFFDF5EB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/base_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    //Please enter your email
                    const Text(
                      'Please enter your email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 邮箱输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Your Email address',
                          filled: true,
                          fillColor: const Color(0xFFFDF5EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Please enter your password
                    const Text(
                      'Please enter your password',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 密码输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: 'Your password',
                          filled: true,
                          fillColor: const Color(0xFFFDF5EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          isDense: true,
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 登录按钮
                    GestureDetector(
                      onTap: isLoading.value ? null : handleLogin,
                      child: Container(
                        width: 280,
                        height: 53,
                        decoration: const BoxDecoration(
                          //背景色#F9E707
                          color: Color(0xFFF9E707),
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        alignment: Alignment.center,
                        child: isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF212121),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: Image.asset(
                    'assets/base/close_button_image.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
