import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils/archive.dart';
import 'package:simple_live_app/app/utils/document.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/history.dart';
import 'package:simple_live_app/requests/webdav_client.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

class RemoteSyncWebDAVController extends BaseController {
  // ui
  var passwordVisible = true.obs;
  var isExpanded = false.obs;
  // ui-用户选择是否同步
  var isSyncFollows = true.obs;
  var isSyncHistories = true.obs;
  var isSyncBlockWord = true.obs;
  var isSyncBilibiliAccount = true.obs;

  late DAVClient davClient;
  var user = "".obs;

  var _userFollowJsonName = 'SimpleLive_follows.json';
  var _userHistoriesJsonName = 'SimpleLive_histories.json';
  var _userBlockedWordJsonName = 'SimpleLive_blocked_word.json';
  var _userBilibiliAccountJsonName = 'SimpleLive_bilibili_account.json';

  @override
  void onInit() {
    doWebDAVInit();
    super.onInit();
  }

  // webDAV 逻辑
  // 初始化webDAV
  void doWebDAVInit() {
    var _uri = LocalStorageService.instance
        .getValue(LocalStorageService.kWebDAVUri, "");
    if (_uri.isEmpty) {
      notLogin.value = true;
    } else {
      user.value = LocalStorageService.instance
          .getValue(LocalStorageService.kWebDAVUser, "");
      var _password = LocalStorageService.instance
          .getValue(LocalStorageService.kWebDAVPassword, "");
      davClient = DAVClient(_uri, user.value, _password);
      checkIsLogin();
    }
  }

  // 检查webDAV登录状态
  Future<void> checkIsLogin() async {
    try {
      // 返回登录结果
      bool value = await davClient.pingCompleter.future;
      notLogin.value = !value;
    } catch (e) {
      Log.e("${e}", StackTrace.current);
      notLogin.value = true;
    }
    ;
  }

  // WebDAV登录
  void doWebDAVLogin(
      String webDAVUri, String webDAVUser, String webDAVPassword) async {
    // 确认登录
    davClient = DAVClient(webDAVUri, webDAVUser, webDAVPassword);
    await checkIsLogin();
    if (!notLogin.value) {
      // 保存到本地
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVUri, webDAVUri);
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVUser, webDAVUser);
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVPassword, webDAVPassword);
      Get.back();
    } else {
      SmartDialog.showToast("WebDAV账号密码验证失败，请重新输入！");
    }
  }

  // WebDAV登出
  void doWebDAVLogout() {
    // 清除本地账号数据
    LocalStorageService.instance.setValue(LocalStorageService.kWebDAVUri, "");
    LocalStorageService.instance.setValue(LocalStorageService.kWebDAVUser, "");
    LocalStorageService.instance
        .setValue(LocalStorageService.kWebDAVPassword, "");
    notLogin.value = true;
  }

  // webDAV上传到云端
  Future<void> doWebDAVUpload() async {
    SmartDialog.showLoading(msg: "正在上传到云端");
    _backupData().then((value) async {
      SmartDialog.dismiss();
      if (value.isNotEmpty) {
        var result = await davClient.backup(Uint8List.fromList(value));
        if (result) {
          SmartDialog.showToast("上传成功");
        } else {
          Log.e("备份失败", StackTrace.current);
          SmartDialog.showToast("上传失败");
        }
      } else {
        SmartDialog.showToast("上传失败");
      }
    });
  }

  // 备份所有数据
  Future<List<int>> _backupData() async {
    final archive = Archive();
    List<int> zipBytes = [];
    // 获取本地备份路径
    var dir = (await getApplicationSupportDirectory()).path;
    var profile = Directory(join(dir, 'backup'));
    if (!profile.existsSync()) {
      profile.createSync();
    }
    try {
      // archive.add(filepath, data_map) 会导致文件损坏
      // follows
      var userFollowList = DBService.instance.getFollowList();
      var dataFollowsMap = {
        'data': userFollowList.map((e) => e.toJson()).toList()
      };
      final userFollowJsonFile = File(join(profile.path, _userFollowJsonName));
      await userFollowJsonFile.writeAsString(jsonEncode(dataFollowsMap));

      // histories
      var userHistoriesList = DBService.instance.getHistores();
      var dataHistoriesMap = {
        'data': userHistoriesList.map((e) => e.toJson()).toList()
      };
      final userHistoriesJsonFile =
          File(join(profile.path, _userHistoriesJsonName));
      await userHistoriesJsonFile.writeAsString(jsonEncode(dataHistoriesMap));

      // blocked_word
      var userShieldList = AppSettingsController.instance.shieldList;
      var dataShieldListMap = {'data': userShieldList.toList()};
      final userBlockedWordJsonFile =
          File(join(profile.path, _userBlockedWordJsonName));
      await userBlockedWordJsonFile
          .writeAsString(jsonEncode(dataShieldListMap));

      // bilibili_account
      var userBiliAccountCookieMap = {
        'data': {'cookie': BiliBiliAccountService.instance.cookie}
      };
      final bilibiliAccountJsonFile =
          File(join(profile.path, _userBilibiliAccountJsonName));
      await bilibiliAccountJsonFile
          .writeAsString(jsonEncode(userBiliAccountCookieMap));
      // 遍历profile路径下的所有文件压缩
      await archive.addDirectoryToArchive(profile.path, profile.path);
      final zipEncoder = ZipEncoder();
      zipBytes = zipEncoder.encode(archive) ?? [];
      profile.clearSync();
    } catch (e) {
      Log.logPrint(e);
      SmartDialog.showToast("备份失败：$e");
    }
    return zipBytes;
  }

  // webDAV恢复到本地
  void doWebDAVRecovery() async {
    SmartDialog.showLoading(msg: "正在恢复到本地");
    final data = await davClient.recovery();
    final archive = await Isolate.run<Archive>(() {
      final zipDecoder = ZipDecoder();
      return zipDecoder.decodeBytes(data);
    });
    for (ArchiveFile file in archive) {
      await _recovery(file);
    }
    SmartDialog.dismiss();
    SmartDialog.showToast('同步完成');
  }
  // todo: 后续迁出实现无感同步
  Future<void> _recovery(ArchiveFile file) async {
    if (file.isFile && file.name.endsWith('.json')) {
      var jsonString = utf8.decode(file.content);
      var jsonData = json.decode(jsonString)['data'];
      // 同步follows
      if (file.name == _userFollowJsonName && isSyncFollows.value) {
        try {
          for (var item in jsonData) {
            var user = FollowUser.fromJson(item);
            await DBService.instance.followBox.put(user.id, user);
            EventBus.instance.emit(Constant.kUpdateFollow, 0);
          }
          Log.i('已同步关注用户列表');
        } catch (e) {
          Log.i('同步关注用户列表失败');
        }
      } else if (file.name == _userHistoriesJsonName && isSyncHistories.value) {
        try {
          for (var item in jsonData) {
            var history = History.fromJson(item);
            if (DBService.instance.historyBox.containsKey(history.id)) {
              var old = DBService.instance.historyBox.get(history.id);
              //如果本地的更新时间比较新，就不更新
              if (old!.updateTime.isAfter(history.updateTime)) {
                continue;
              }
            }
            await DBService.instance.addOrUpdateHistory(history);
          }
          Log.i('已同步用户观看历史记录');
        } catch (e) {
          Log.i('同步用户观看历史记录失败');
        }
      } else if (file.name == _userBlockedWordJsonName &&
          isSyncBlockWord.value) {
        try {
          for (var keyword in jsonData) {
            AppSettingsController.instance.addShieldList(keyword.trim());
          }
          Log.i('已同步用户屏蔽词');
        } catch (e) {
          Log.i('同步用户屏蔽词失败');
        }
      } else if (file.name == _userBilibiliAccountJsonName &&
          isSyncBilibiliAccount.value) {
        try {
          var cookie = jsonData['cookie'];
          BiliBiliAccountService.instance.setCookie(cookie);
          BiliBiliAccountService.instance.loadUserInfo();
          Log.i('已同步哔哩哔哩账号');
        } catch (e) {
          Log.i('同步哔哩哔哩账号失败：${e}');
        }
      } else {
        return;
      }
    } else {
      Log.i('不是正确的文件名');
    }
  }

  // ui控制--密码可见控制
  void changePasswordVisible() {
    passwordVisible.value = !passwordVisible.value;
  }

  void changeIsSyncFollows() {
    isSyncFollows.value = !isSyncFollows.value;
  }

  void changeIsSyncHistories() {
    isSyncHistories.value = !isSyncHistories.value;
  }

  void changeIsSyncBlockWord() {
    isSyncBlockWord.value = !isSyncBlockWord.value;
  }

  void changeIsSyncBilibiliAccount() {
    isSyncBilibiliAccount.value = !isSyncBilibiliAccount.value;
  }

  void changeExpanded() {
    isExpanded.value = !isExpanded.value;
  }
}