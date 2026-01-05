import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    Locale? locale = const Locale('en');
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          // 状态栏字体黑色
          themeMode: ThemeMode.light,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
            useMaterial3: false,
            appBarTheme: AppBarTheme(
              foregroundColor: Colors.black,
              titleTextStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
              elevation: 0,
            ),
          ),
          locale: locale,
          // NOTE: Previously used GetX features (translations, getPages, initialRoute, EasyLoading).
          // Those have been removed and replaced with a Riverpod-friendly app entry.
          // Replace the `home` below with your GoRouter/Router or a home screen as needed.
          home: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}