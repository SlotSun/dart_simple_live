import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/utils/listen_fourth_button.dart';
import 'package:simple_live_app/firebase_options.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/modules/other/debug_log_page.dart';
import 'package:simple_live_app/modules/settings/appstyle_settings/appstyle_setting_contorller.dart';
import 'package:simple_live_app/routes/app_analytics_observer.dart';
import 'package:simple_live_app/routes/app_pages.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/douyin_account_service.dart';
import 'package:simple_live_app/services/firebase_service.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/history_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/migration_service.dart';
import 'package:simple_live_app/services/sync_service.dart';
import 'package:simple_live_app/services/window_service.dart';
import 'package:simple_live_app/src/rust/frb_generated.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:window_manager/window_manager.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // init-queue:
  // window(first)->migration->media_kit->Hive->services->start
  // window(second)->open
  await RustLib.init();
  await MigrationService.migrateData();
  MediaKit.ensureInitialized();
  await Hive.initFlutter(
    (!Platform.isAndroid && !Platform.isIOS)
        ? (await getApplicationSupportDirectory()).path
        : null,
  );
  //初始化服务
  await initServices();
  await initWindow();

  await MigrationService.migrateDataByVersion();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  //设置状态栏为透明
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  );
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  runApp(const MyApp());
}

Future initWindow() async {
  if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    return;
  }
  await windowManager.ensureInitialized();
  WindowService.instance.init();
}

Future initServices() async {
  Hive.registerAdapter(FollowUserAdapter());
  Hive.registerAdapter(HistoryAdapter());
  Hive.registerAdapter(FollowUserTagAdapter());

  //包信息
  Utils.packageInfo = await PackageInfo.fromPlatform();
  //本地存储
  Log.d("Init LocalStorage Service");
  await Get.put(LocalStorageService()).init();
  await Get.put(DBService()).init();
  //初始化设置控制器
  Get.put(AppSettingsController());

  await Get.put(AppStyleSettingController()).init();

  Get.put(BiliBiliAccountService());

  Get.put(DouyinAccountService());

  Get.put(SyncService());

  Get.put(FollowService());

  Get.put(HistoryService());

  // 移动平台不使用 windowManager
  if(!Platform.isAndroid && !Platform.isIOS){
    Get.put(WindowService());
  }

  // only android use firebase
  if(Platform.isAndroid){
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Get.put(FirebaseService());
  }

  initCoreLog();
}

void initCoreLog() {
  //日志信息
  CoreLog.enableLog =
      !kReleaseMode || AppSettingsController.instance.logEnable.value;
  CoreLog.requestLogType = RequestLogType.short;
  CoreLog.onPrintLog = (level, msg) {
    switch (level) {
      case Level.debug:
        Log.d(msg);
        break;
      case Level.error:
        Log.e(msg, StackTrace.current);
        break;
      case Level.info:
        Log.i(msg);
        break;
      case Level.warning:
        Log.w(msg);
        break;
      default:
        Log.logPrint(msg);
    }
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDynamicColor = AppStyleSettingController.instance.isDynamic.value;
    Color styleColor = Color(AppStyleSettingController.instance.styleColor.value);
    return DynamicColorBuilder(
        builder: ((ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme? lightColorScheme;
      ColorScheme? darkColorScheme;
      if (lightDynamic != null && darkDynamic != null && isDynamicColor) {
        lightColorScheme = lightDynamic;
        darkColorScheme = darkDynamic;
      } else {
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: styleColor,
          brightness: Brightness.light,
        );
        darkColorScheme = ColorScheme.fromSeed(
            seedColor: styleColor, brightness: Brightness.dark);
      }
      return Obx(
        () => GetMaterialApp(
          title: "Slive",
          theme: AppStyle.light(
            fontFamily: AppStyleSettingController.instance.curFontName.value,
          ).copyWith(colorScheme: lightColorScheme),
          darkTheme: AppStyle.darkTheme(
            fontFamily: AppStyleSettingController.instance.curFontName.value,
          ).copyWith(colorScheme: darkColorScheme),
          themeMode: ThemeMode
              .values[Get.find<AppSettingsController>().themeMode.value],
          initialRoute: RoutePath.kIndex,
          getPages: AppPages.routes,
          //国际化
          locale: const Locale("zh", "CN"),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale("zh", "CN")],
          logWriterCallback: (text, {bool? isError}) {
            Log.addDebugLog(text, (isError ?? false) ? Colors.red : Colors.grey);
            Log.writeLog(text, (isError ?? false) ? Level.error : Level.info);
          },
          //debugShowCheckedModeBanner: false,
          navigatorObservers: [
            FlutterSmartDialog.observer,
            if (Platform.isAndroid) AppAnalyticsObserver.observer
          ],
          builder: FlutterSmartDialog.init(
            loadingBuilder: ((msg) => const AppLoaddingWidget()),
            //字体大小不跟随系统变化
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Stack(
                children: [
                  //侧键返回
                  RawGestureDetector(
                    excludeFromSemantics: true,
                    gestures: <Type, GestureRecognizerFactory>{
                      FourthButtonTapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              FourthButtonTapGestureRecognizer>(
                        () => FourthButtonTapGestureRecognizer(),
                        (FourthButtonTapGestureRecognizer instance) {
                          instance.onTapDown = (TapDownDetails details) async {
                            //如果处于全屏状态，退出全屏
                            if (!Platform.isAndroid && !Platform.isIOS) {
                              if (await windowManager.isFullScreen()) {
                                await windowManager.setFullScreen(false);
                                return;
                              }
                            }
                            Get.back();
                          };
                        },
                      ),
                    },
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent event) async {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          // ESC退出全屏
                          // 如果处于全屏状态，退出全屏
                          if (!Platform.isAndroid && !Platform.isIOS) {
                            if (await windowManager.isFullScreen()) {
                              await windowManager.setFullScreen(false);
                              EventBus.instance.emit(EventBus.kEscapePressed, 0);
                              return;
                            }
                          }
                        }
                      },
                      child: child!,
                    ),
                  ),

                  //查看DEBUG日志按钮
                  //只在Debug、Profile模式显示
                  Visibility(
                    visible: !kReleaseMode,
                    child: Positioned(
                      right: 12,
                      bottom: 100 + context.mediaQueryViewPadding.bottom,
                      child: Opacity(
                        opacity: 0.4,
                        child: ElevatedButton(
                          child: const Text("DEBUG LOG"),
                          onPressed: () {
                            Get.bottomSheet(
                              const DebugLogPage(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }));
  }
}
