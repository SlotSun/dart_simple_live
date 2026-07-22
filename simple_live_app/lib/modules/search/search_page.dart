import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/app/design_system/app_theme_extension.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/search/search_controller.dart';
import 'package:simple_live_app/modules/search/search_list_view.dart';

class SearchPage extends GetView<AppSearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.appTheme;
    final searchRadius = BorderRadius.circular(24);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leadingWidth: 52,
        leading: IconButton(
          onPressed: Get.back,
          tooltip: '返回',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        toolbarHeight: 68,
        title: Padding(
          padding: const EdgeInsets.only(right: AppDesignTokens.space12),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: controller.searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索直播间或主播',
                isDense: true,
                filled: true,
                fillColor: semantic.secondarySurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.space12,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: semantic.textTertiary,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  onPressed: controller.doSearch,
                  tooltip: '搜索',
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: searchRadius,
                  borderSide: BorderSide(color: semantic.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: searchRadius,
                  borderSide: BorderSide(color: semantic.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: searchRadius,
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => controller.doSearch(),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: semantic.border),
              ),
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: AppDesignTokens.space12),
                  Obx(
                    () => Container(
                      height: 40,
                      padding: const EdgeInsets.only(
                        left: AppDesignTokens.space12,
                        right: AppDesignTokens.space8,
                      ),
                      decoration: BoxDecoration(
                        color: semantic.secondarySurface,
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radius10,
                        ),
                        border: Border.all(color: semantic.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: controller.searchMode.value,
                          isDense: true,
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radius10,
                          ),
                          dropdownColor: semantic.elevatedSurface,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: semantic.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('房间'),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('主播'),
                            ),
                          ],
                          onChanged: (value) {
                            controller.searchMode.value = value ?? 0;
                            controller.doSearch();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.space8),
                  Expanded(
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
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller.tabController,
        children: Sites.supportSites
            .map(
              (site) => SearchListView(site.id),
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
            width: 18,
            height: 18,
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
