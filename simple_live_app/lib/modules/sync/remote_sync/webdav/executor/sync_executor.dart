import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/interface/sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/blockwords_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/follow_block_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/follow_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/history_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/settings_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/resources/user_account_cookie_sync_resource.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/common/sync_mode.dart';
import 'package:simple_live_app/requests/webdav_client.dart';

class SyncExecutor {
  static final SyncExecutor instance = SyncExecutor._();

  late DAVClient _davClient;

  SyncExecutor._();

  final List<SyncResource> _resources = [
    FollowSyncResource(),
    HistorySyncResource(),
    BlockwordsSyncResource(),
    UserAccountCookieSyncResource(),
    SettingsSyncResource(),
    FollowBlockSyncResource(),
  ];

  void buildExecutorAttr(
    DAVClient davClient, {
    bool isSyncFollows = true,
    bool isSyncHistories = true,
    bool isSyncBlockWord = true,
    bool isSyncAccount = true,
    bool isSyncSetting = true,
  }) {
    _davClient = davClient;
    _resources.addAll([
      if (isSyncFollows) FollowSyncResource(),
      if (isSyncHistories) HistorySyncResource(),
      if (isSyncBlockWord) BlockwordsSyncResource(),
      if (isSyncAccount) UserAccountCookieSyncResource(),
      if (isSyncSetting) SettingsSyncResource(),
      FollowBlockSyncResource(),
    ]);
  }

  // fetch -> local-> remote -> select sync-mode
  // migration is needed after recover data from remote
  // migration depends on setting-kHiveDbVer, user did not select sync setting maybe
  // todo: version.json is required, plan to implement this feature in v1.8.10
  Future<void> sync(SyncMode mode) async {
    final remoteArchive = await _doWebDAVFetch();

    final uploadArchive = Archive();

    for (final resource in _resources) {
      final local = await resource.loadLocal();
      final remote = remoteArchive == null ? null : resource.loadRemote(remoteArchive);

      switch (mode) {
        case SyncMode.uploadAll:
          resource.saveRemote(uploadArchive, local);
          break;

        case SyncMode.recoveryAll:
          if (remote != null) {
            await resource.saveLocal(remote);
          }
          break;

        case SyncMode.bidirectional:
          final merged = remote == null ? local : resource.merge(local, remote);

          await resource.saveLocal(merged);
          resource.saveRemote(uploadArchive, merged);
          break;
      }
    }

    if (mode != SyncMode.recoveryAll) {
      final zipBytes = ZipEncoder().encode(uploadArchive);
      await _davClient.backup(Uint8List.fromList(zipBytes));
    }
  }

  // 拉取webdav已有备份
  Future<Archive?> _doWebDAVFetch() async {
    List<int> data;
    Archive? archive;
    try {
      data = await _davClient.recovery();
    } catch (e, s) {
      Log.e("WebDAV恢复失败$e", s);
      return null;
    }
    archive = await Isolate.run<Archive>(() {
      final zipDecoder = ZipDecoder();
      return zipDecoder.decodeBytes(data);
    });
    return archive;
  }
}
