import 'package:flutter/material.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/manager/user_manager.dart';
import 'package:sp_util/sp_util.dart';

import 'app_enum.dart';

class AppConfig with WidgetsBindingObserver {
  AppConfig.privateConstructor();

  // TODO: 打包时需要修改
  AppEnv appEnv = AppEnv.dev;
  static final AppConfig shared = AppConfig.privateConstructor();

  /// 项目运行入口
  run(AppEnv env) async {
    WidgetsBinding.instance.addObserver(this);
    appEnv = env;
    AppDevice().init();

    // 初始化本地存储
    await SpUtil.getInstance();

    // 恢复上次登录的用户 session
    await UserManager.shared.restore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {}
}