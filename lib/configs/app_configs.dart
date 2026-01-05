import 'package:flutter/material.dart';

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

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {

  }
}