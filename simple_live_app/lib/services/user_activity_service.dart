import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/widgets/user_activity_dialog.dart';

class UserActivityService extends GetxService {
  static UserActivityService get instance => Get.find<UserActivityService>();

  Timer? _checkTimer;
  DateTime _lastActiveTime = DateTime.now();
  bool _isDialogOpen = false;

  @override
  void onInit() {
    super.onInit();
    ever(AppSettingsController.instance.userActivityCheckEnable, (bool enable) {
      if (enable) {
        startCheck();
      } else {
        stopCheck();
      }
    });

    if (AppSettingsController.instance.userActivityCheckEnable.value) {
      startCheck();
    }
  }

  void startCheck() {
    _checkTimer?.cancel();
    updateActivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkActivity();
    });
    Log.i("UserActivityService started");
  }

  void stopCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    Log.i("UserActivityService stopped");
  }

  void updateActivity() {
    _lastActiveTime = DateTime.now();
    if (_isDialogOpen) {
      _isDialogOpen = false;
      Get.back();
    }
  }

  void checkActivity() {
    if (_isDialogOpen) return;

    final timeoutMinutes =
        AppSettingsController.instance.userActivityTimeout.value;
    final diff = DateTime.now().difference(_lastActiveTime);

    if (diff.inMinutes >= timeoutMinutes) {
      showConfirmDialog();
    }
  }

  void showConfirmDialog() {
    _isDialogOpen = true;
    int countdown = 60;
    Timer? dialogTimer;

    Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: "User Activity Check",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (dialogTimer == null) {
              dialogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (countdown > 0) {
                  setState(() {
                    countdown--;
                  });
                } else {
                  timer.cancel();
                  if (_isDialogOpen) {
                    exitApp();
                  }
                }
              });
            }
            return UserActivityDialog(
              countdown: countdown,
              onKeepActive: () {
                dialogTimer?.cancel();
                _isDialogOpen = false;
                updateActivity();
                Get.back();
              },
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    ).then((_) {
       dialogTimer?.cancel();
       _isDialogOpen = false;
    });
  }

  void exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
