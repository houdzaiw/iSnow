import 'package:flutter/material.dart';
import 'package:project/configs/app_device.dart';
import 'package:project/manager/user_manager.dart';
import 'package:sp_util/sp_util.dart';

import 'app_enum.dart';

class AppConfig with WidgetsBindingObserver {
  AppConfig.privateConstructor();

  /// 当前版本固定使用 Travel test 环境；不允许启动阶段回退旧环境。
  AppEnv appEnv = AppEnv.test;
  static final AppConfig shared = AppConfig.privateConstructor();

  /// 项目运行入口
  Future<void> run(AppEnv env) async {
    WidgetsBinding.instance.addObserver(this);
    appEnv = env;
    await AppDevice().init();

    // 初始化本地存储
    await SpUtil.getInstance();

    // 恢复上次登录的用户 session
    await UserManager.shared.restore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {}
}
