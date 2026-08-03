import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'configs/app_routers.dart';
import 'localization/app_localizations.dart';
import 'manager/locale_provider.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(appLocaleProvider);
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (BuildContext context, Widget? child) =>
                MaterialApp.router(
                  routerConfig: goRouter,
                  debugShowCheckedModeBanner: false,
                  // 状态栏字体黑色
                  themeMode: ThemeMode.light,
                  theme: AppTheme.light,
                  locale: locale,
                  supportedLocales: const [Locale('en'), Locale('zh')],
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                ),
          );
        },
      ),
    );
  }
}
