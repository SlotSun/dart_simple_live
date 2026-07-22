import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: AppDesignTokens.space24,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '发现直播',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: semantic.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '精选推荐',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: semantic.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.toSearch,
            tooltip: '搜索直播间或主播',
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: AppDesignTokens.space8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: semantic.border),
              ),
            ),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: TabBar(
                controller: controller.tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.space12,
                ),
                tabs: Sites.supportSites.map(_SiteTab.new).toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: Sites.supportSites
            .map(
              (site) => HomeListView(site.id),
            )
            .toList(),
      ),
    );
  }
}

class _SiteTab extends StatelessWidget {
  const _SiteTab(this.site);

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            site.logo,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: AppDesignTokens.space8),
          Text(
            site.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
