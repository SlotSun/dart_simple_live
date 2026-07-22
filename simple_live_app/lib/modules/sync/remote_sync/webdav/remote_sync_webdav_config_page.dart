import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/sync/remote_sync/webdav/remote_sync_webdav_controller.dart';
import 'package:simple_live_app/widgets/none_border_circular_textfield.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class RemoteSyncWebDAVConfigPage extends StatefulWidget {
  const RemoteSyncWebDAVConfigPage({super.key});

  @override
  State<RemoteSyncWebDAVConfigPage> createState() =>
      _RemoteSyncWebDAVConfigPageState();
}

class _RemoteSyncWebDAVConfigPageState
    extends State<RemoteSyncWebDAVConfigPage> {
  late TextEditingController _urlController;
  late TextEditingController _userNameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    _urlController = TextEditingController();
    _userNameController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV账号配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: '配置帮助',
            onPressed: () {
              Utils.showInformationHelpDialog(
                content: [
                  const Text('此功能可以将您的数据备份到 WebDAV 服务器中或者进行数据恢复。\n'),
                  const Text(
                    'WebDAV 服务器地址请以 http:// 或 https:// 开头，如坚果云（点击复制）：',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text: 'https://dav.jianguoyun.com/dav/',
                          ),
                        );
                        SmartDialog.showToast('复制成功');
                      },
                      child: Text(
                        'https://dav.jianguoyun.com/dav/',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: AppDesignTokens.space8),
        ],
      ),
      body: GetX<RemoteSyncWebDAVController>(
        builder: (controller) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDesignTokens.space16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(14),
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radius12,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(36),
                        ),
                      ),
                      child: Text(
                        '填写您的 WebDAV 服务地址与账号信息。凭据将保存在本机。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space16),
                    SettingsCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesignTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            NoneBorderCircularTextField(
                              editingController: _urlController,
                              labelText: 'WebDAV服务器地址',
                              hintText: '请以 http:// 或 https:// 开头',
                              prefixIcon: const Icon(Icons.public_rounded),
                              trailing: IconButton(
                                tooltip: '清空地址',
                                onPressed: _urlController.clear,
                                icon: const Icon(Icons.cancel, size: 20),
                              ),
                            ),
                            NoneBorderCircularTextField(
                              editingController: _userNameController,
                              labelText: '账号',
                              prefixIcon: const Icon(Icons.account_circle),
                              trailing: IconButton(
                                tooltip: '清空账号',
                                onPressed: _userNameController.clear,
                                icon: const Icon(Icons.cancel, size: 20),
                              ),
                            ),
                            NoneBorderCircularTextField(
                              editingController: _passwordController,
                              labelText: '密码',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              obscureText: controller.passwordVisible.value,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '清空密码',
                                    onPressed: _passwordController.clear,
                                    icon: const Icon(Icons.cancel, size: 20),
                                  ),
                                  IconButton(
                                    tooltip: controller.passwordVisible.value
                                        ? '显示密码'
                                        : '隐藏密码',
                                    onPressed: controller.changePasswordVisible,
                                    icon: Icon(
                                      controller.passwordVisible.value
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDesignTokens.space12),
                            FilledButton.icon(
                              onPressed: () {
                                controller.doWebDAVLogin(
                                  _urlController.text,
                                  _userNameController.text,
                                  _passwordController.text,
                                );
                              },
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('登录'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
