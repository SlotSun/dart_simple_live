// only for Android
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';

class FirebaseService extends GetxService {
  static FirebaseService get instance => Get.find<FirebaseService>();

  @override
  onInit() {
    bool e = AppSettingsController.instance.firebaseEnable.value;
    setCrashlytics(e);
    super.onInit();
  }

  static Future<void> setCrashlytics(bool enable) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enable);

    if (enable) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }else{
      FlutterError.onError = FlutterError.dumpErrorToConsole;
    }
  }
}
