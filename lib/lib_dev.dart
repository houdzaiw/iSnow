import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'classes/room/gift/room_gift_repository.dart';
import 'configs/app_configs.dart';
import 'configs/app_enum.dart';
import 'lib_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.shared.run(AppEnv.dev);
  await initializeDateFormatting('zh_CN');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  unawaited(preloadRoomGiftCatalog());
  runApp(const MyApp());
}
