import 'dart:convert';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/models/sync_client_info_model.dart';
import 'package:simple_live_app/requests/sync_client_request.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/platform_service.dart';
import 'package:simple_live_app/services/sync_service.dart';

class SyncDeviceController extends BaseController {
  final SyncClinet client;
  final SyncClientInfoModel info;
  SyncDeviceController({required this.client, required this.info});
  SyncClientRequest request = SyncClientRequest();

  Future<bool> showOverlayDialog() async {
    var overlay = await Utils.showAlertDialog(
      "是否覆盖远端数据？",
      title: "数据覆盖",
      confirm: "覆盖",
      cancel: "不覆盖",
    );
    return overlay;
  }

  void syncFollowAndTag() async {
    try {
      var overlay = await showOverlayDialog();
      SmartDialog.showLoading(msg: "同步中...");
      var users = DBService.instance.getFollowList();
      var tags = DBService.instance.getFollowTagList();
      var data = json.encode(users.map((e) => e.toJson()).toList());
      var dataT = json.encode(tags.map((e) => e.toJson()).toList());
      await request.syncFollow(client, data, overlay: overlay);
      // 标签和关注必须同时同步
      await request.syncTag(client, dataT, overlay: overlay);
      SmartDialog.showToast("已同步关注列表和标签");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncHistory() async {
    try {
      var overlay = await showOverlayDialog();
      SmartDialog.showLoading(msg: "同步中...");
      var histores = DBService.instance.getHistories();
      var data = json.encode(histores.map((e) => e.toJson()).toList());
      await request.syncHistory(client, data, overlay: overlay);
      SmartDialog.showToast("已同步历史记录");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncBlockedWord() async {
    try {
      var overlay = await showOverlayDialog();
      SmartDialog.showLoading(msg: "同步中...");
      var shieldList = AppSettingsController.instance.shieldList;
      var data = json.encode(shieldList.toList());
      await request.syncBlockedWord(client, data, overlay: overlay);
      SmartDialog.showToast("已同步屏蔽词");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  // 通用平台账号同步
  void syncAccount({required String siteId}) async {
    try {
      Account account = PlatformService.instance.accountList.firstWhere((ac) => ac.siteId == siteId);
      if (account.credential.isEmpty) {
        SmartDialog.showToast("未登录$siteId");
        return;
      }
      SmartDialog.showLoading(msg: "同步中...");

      await request.syncAccount(client, account);
      SmartDialog.showToast("已同步$siteId账号");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }
}
