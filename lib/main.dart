import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/provider/locale_provider.dart';
import 'package:flutter_base/provider/theme_provider.dart';
import 'package:flutter_base/res/constant.dart';
import 'package:flutter_base/routers/not_found_page.dart';
import 'package:flutter_base/routers/routers.dart';
import 'package:flutter_base/util/device_utils.dart';
import 'package:flutter_base/util/theme_utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sp_util/sp_util.dart';
import 'package:flutter_base/res/colors.dart';
import 'package:flutter_base/util/handle_error_utils.dart';
import 'package:flutter_base/util/log_utils.dart';

import 'home/splash_page.dart';
import 'net/dio_utils.dart';
import 'net/intercept.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpUtil.getInstance();

  handleError(runApp( MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({Key? key, this.home, this.theme}) : super(key: key) {
    Log.init();
    initDio();
    Routes.initRoutes();
    //initQuickActions();
  }

  final Widget? home;
  final ThemeData? theme;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  void initDio() {
    final List<Interceptor> interceptors = <Interceptor>[];

    /// 统一添加身份验证请求头
    //interceptors.add(AuthInterceptor());

    /// 刷新Token
    //interceptors.add(TokenInterceptor());

    /// 打印Log(生产模式去除)
    if (!Constant.inProduction) {
      interceptors.add(LoggingInterceptor());
    }

    /// 适配数据(根据自己的数据结构，可自行选择添加)
    interceptors.add(AdapterInterceptor());
    configDio(
      baseUrl: 'https://www.wanandroid.com/',
      interceptors: interceptors,
    );
  }

  // void initQuickActions() {
  //   if (Device.isMobile) {
  //     const QuickActions quickActions = QuickActions();
  //     if (Device.isIOS) {
  //       // Android每次是重新启动activity，所以放在了splash_page处理。
  //       // 总体来说使用不方便，这种动态的方式在安卓中局限性高。这里仅做练习使用。
  //       quickActions.initialize((String shortcutType) async {
  //         if (shortcutType == 'demo') {
  //           navigatorKey.currentState?.push<dynamic>(MaterialPageRoute<dynamic>(
  //             builder: (BuildContext context) => const DemoPage(),
  //           ));
  //         }
  //       });
  //     }
  //
  //     quickActions.setShortcutItems(<ShortcutItem>[
  //       const ShortcutItem(
  //           type: 'demo',
  //           localizedTitle: 'Demo',
  //           icon: 'flutter_dash_black'
  //       ),
  //     ]);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final Widget app = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider())
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (_, ThemeProvider provider, LocaleProvider localeProvider, __) {
          return _buildMaterialApp(provider, localeProvider);
        },
      ),
    );

    /// Toast 配置
    return OKToast(
        child: app,
        backgroundColor: Colors.black54,
        textPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        radius: 20.0,
        position: ToastPosition.bottom
    );
  }

  Widget _buildMaterialApp(ThemeProvider provider, LocaleProvider localeProvider) {
    return MaterialApp(
      title: 'Flutter Deer',
      // showPerformanceOverlay: true, //显示性能标签
      // debugShowCheckedModeBanner: false, // 去除右上角debug的标签
      // checkerboardRasterCacheImages: true,
      // showSemanticsDebugger: true, // 显示语义视图
      // checkerboardOffscreenLayers: true, // 检查离屏渲染
      theme: theme ?? provider.getTheme(),
      darkTheme: provider.getTheme(isDarkMode: true),
      themeMode: provider.getThemeMode(),
      home: home ?? const SplashPage(),
      onGenerateRoute: Routes.router.generator,
      // localizationsDelegates: DeerLocalizations.localizationsDelegates,
      // supportedLocales: DeerLocalizations.supportedLocales,
      locale: localeProvider.locale,
      navigatorKey: navigatorKey,
      builder: (BuildContext context, Widget? child) {
        /// 仅针对安卓
        if (Device.isAndroid) {
          /// 切换深色模式会触发此方法，这里设置导航栏颜色
          ThemeUtils.setSystemNavigationBar(provider.getThemeMode());
        }

        /// 保证文字大小不受手机系统设置影响 https://www.kikt.top/posts/flutter/layout/dynamic-text/
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },

      /// 因为使用了fluro，这里设置主要针对Web
      onUnknownRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const NotFoundPage(),
        );
      },
      restorationScopeId: 'app',
    );
  }
}
