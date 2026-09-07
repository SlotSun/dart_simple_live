import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/common/sync_mode.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/executor/sync_executor.dart';
import 'package:simple_live_app/requests/webdav_client.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_app/services/migration_service.dart';

class RemoteSyncWebDAVController extends BaseController {
  // ui
  var passwordVisible = true.obs;

  // ui-用户选择是否同步
  var isSyncFollows = true.obs;
  var isSyncHistories = true.obs;
  var isSyncBlockWord = true.obs;
  var isSyncAccount = true.obs;
  var isSyncSetting = true.obs;

  late DAVClient davClient;
  var user = "--".obs;
  var lastRecoverTime = "--".obs;
  var lastUploadTime = "--".obs;
  var uri = "";
  var password = "";
  var webDavBackupDirectory = "/simple_live_app".obs;

  @override
  void onInit() {
    doWebDAVInit();
    super.onInit();
  }

  void setWebDavBackupDirectory({required String newDirectory}) {
    if (newDirectory == webDavBackupDirectory.value) {
      return;
    }
    // 防呆
    final filePathCheck = RegExp(r'^/([^/]+)(/[^/]+)*$');
    if (!filePathCheck.hasMatch(newDirectory)) {
      SmartDialog.showToast("请输入正确的文件路径");
      return;
    }
    webDavBackupDirectory.value = newDirectory;
    LocalStorageService.instance.setValue(
      LocalStorageService.kWebDAVDirectory,
      webDavBackupDirectory.value,
    );
    // 重定义/应该单例化
    davClient = DAVClient(
      uri,
      user.value,
      password,
      webDAVDirectory: webDavBackupDirectory.value,
    );
  }

  // webDAV 逻辑
  // 初始化webDAV
  void doWebDAVInit() {
    uri = LocalStorageService.instance
        .getValue(LocalStorageService.kWebDAVUri, "");
    if (uri.isEmpty) {
      notLogin.value = true;
    } else {
      user.value = LocalStorageService.instance
          .getValue(LocalStorageService.kWebDAVUser, "");
      password = LocalStorageService.instance
          .getValue(LocalStorageService.kWebDAVPassword, "");
      webDavBackupDirectory.value = LocalStorageService.instance.getValue(
        LocalStorageService.kWebDAVDirectory,
        "/simple_live_app",
      );
      davClient = DAVClient(
        uri,
        user.value,
        password,
        webDAVDirectory: webDavBackupDirectory.value,
      );
      // 从未同步过默认为最古早数据
      lastRecoverTime.value = Utils.parseTime(
        DateTime.fromMillisecondsSinceEpoch(
          LocalStorageService.instance.getValue(
            LocalStorageService.kWebDAVLastRecoverTime,
            DateTime(2026, 1, 1).millisecondsSinceEpoch,
          ),
        ),
      );
      lastUploadTime.value = Utils.parseTime(
        DateTime.fromMillisecondsSinceEpoch(
          LocalStorageService.instance.getValue(
            LocalStorageService.kWebDAVLastUploadTime,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
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
      Log.e("$e", StackTrace.current);
      notLogin.value = true;
    }
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
      user.value = webDAVUser;
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVPassword, webDAVPassword);
      Get.back();
      SmartDialog.showToast("登录成功！");
    } else {
      SmartDialog.showToast("WebDAV账号密码验证失败，请重新输入！");
    }
  }

  // WebDAV登出
  @override
  Future<void> onLogout() async {
    var result = await Utils.showAlertDialog("确定要登出WebDAV账号？", title: "退出登录");
    if (result) {
      // 清除本地账号数据
      LocalStorageService.instance.setValue(LocalStorageService.kWebDAVUri, "");
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVUser, "");
      LocalStorageService.instance
          .setValue(LocalStorageService.kWebDAVPassword, "");
      notLogin.value = true;
    }
  }

  // webDAV上传到云端
  Future<void> doWebDAVUpload() async {
    SmartDialog.showLoading(msg: "正在上传到云端");
    try {
      await _sync(mode: SyncMode.uploadAll);
      SmartDialog.dismiss();
      SmartDialog.showToast("上传成功");
      DateTime uploadTime = DateTime.now();
      lastUploadTime.value = Utils.parseTime(uploadTime);
      LocalStorageService.instance.setValue(
          LocalStorageService.kWebDAVLastUploadTime,
          uploadTime.millisecondsSinceEpoch);
    } catch (e, s) {
      Log.e("备份失败：$e", s);
      SmartDialog.dismiss();
      SmartDialog.showToast("上传失败");
    }
  }


  // webDAV恢复到本地
  void doWebDAVRecovery() async {
    SmartDialog.showLoading(msg: "正在恢复到本地");
    try {
      await _sync(mode: SyncMode.recoveryAll);
      SmartDialog.dismiss();
      SmartDialog.showToast('同步完成');
      DateTime syncTime = DateTime.now();
      lastRecoverTime.value = Utils.parseTime(syncTime);
      LocalStorageService.instance.setValue(
          LocalStorageService.kWebDAVLastRecoverTime,
          syncTime.millisecondsSinceEpoch);
    }catch(e,s){
      Log.e("恢复数据：$e", s);
      SmartDialog.dismiss();
      SmartDialog.showToast('同步失败');
    }
  }

  void doWebDAVBidirectional() async {
    SmartDialog.showLoading(msg: "正在双向同步数据");
    try {
      await _sync(mode: SyncMode.bidirectional);
      SmartDialog.dismiss();
      SmartDialog.showToast('同步完成');
      DateTime syncTime = DateTime.now();
      lastRecoverTime.value = Utils.parseTime(syncTime);
      LocalStorageService.instance.setValue(
          LocalStorageService.kWebDAVLastRecoverTime,
          syncTime.millisecondsSinceEpoch);
      LocalStorageService.instance.setValue(
          LocalStorageService.kWebDAVLastUploadTime,
          syncTime.millisecondsSinceEpoch);
    }catch(e,s){
      Log.e("双向同步数据：$e", s);
      SmartDialog.dismiss();
      SmartDialog.showToast('双向同步失败');
    }
  }

  Future<void> _sync({required SyncMode mode}) async{
    SyncExecutor.instance.buildExecutorAttr(
      davClient,
      isSyncFollows: isSyncFollows.value,
      isSyncHistories: isSyncHistories.value,
      isSyncAccount: isSyncAccount.value,
      isSyncBlockWord: isSyncBlockWord.value,
      isSyncSetting: isSyncSetting.value,
    );
    await SyncExecutor.instance.sync(mode);
    // 外部额外进行一次数据同步是非常糟糕的设计
    // 历史数据设计问题
    // history.watchSec 有可能被用户删除掉了/存在
    // follow.watchSec 在4da4267d690d4b7644eea3b85fca8c5fb61da60a前关注存在和history有数据差异
    // todo: 需要一次数据同步后，并限制用户完全删除history
    MigrationService.migrateDataByVersion();
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

  void changeIsSyncAccount() {
    isSyncAccount.value = !isSyncAccount.value;
  }

  void changeIsSyncSetting() {
    isSyncSetting.value = !isSyncSetting.value;
  }
}
