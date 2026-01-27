
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'configs/app_configs.dart';
import 'configs/app_enum.dart';
import 'configs/app_device.dart';
import 'lib_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.shared.run(AppEnv.dev);

  // 初始化设备信息
  await AppDevice().init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}