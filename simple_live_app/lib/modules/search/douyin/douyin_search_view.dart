import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/modules/search/douyin/douyin_search_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';

class DouyinSearchView extends StatelessWidget {
  const DouyinSearchView({super.key});

  DouyinSearchController get controller => Get.find<DouyinSearchController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return KeepAliveWrapper(
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignTokens.space16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: semantic.elevatedSurface,
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radius16,
                      ),
                      border: Border.all(color: semantic.border),
                      boxShadow: [
                        BoxShadow(
                          color: semantic.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDesignTokens.space24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(18),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.travel_explore_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.space16),
                          Text(
                            '暂不支持抖音站内搜索',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: semantic.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.space8),
                          Text(
                            '请在浏览器中搜索，然后复制直播间链接进行解析。',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: semantic.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.space16),
                          FilledButton.tonalIcon(
                            onPressed: controller.openBrowser,
                            icon: const Icon(Icons.open_in_browser_rounded),
                            label: const Text('打开浏览器'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (Platform.isAndroid || Platform.isIOS)
            InAppWebView(
              onWebViewCreated: controller.onWebViewCreated,
              onLoadStop: controller.onLoadStop,
              onLoadStart: controller.onLoadStart,
              initialSettings: InAppWebViewSettings(
                useOnLoadResource: true,
                userAgent:
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1 Edg/118.0.0.0',
                useShouldOverrideUrlLoading: true,
              ),
              onCreateWindow: controller.onCreateWindow,
              shouldOverrideUrlLoading:
                  (webController, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) {
                  return NavigationActionPolicy.ALLOW;
                }
                if (uri.host == 'live.douyin.com') {
                  final regExp = RegExp(r'live\.douyin\.com/([\d|\w]+)');
                  final id = regExp.firstMatch(uri.toString())?.group(1) ?? '';

                  AppNavigator.toLiveRoomDetail(
                    site: controller.site,
                    roomId: id,
                  );
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
          Obx(
            () => Visibility(
              visible: controller.pageLoadding.value,
              child: const AppLoaddingWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
