import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/design_system/app_design_tokens.dart';
import 'package:simple_live_app/widgets/settings/settings_tile.dart';

class _MenuCheckController<T> extends GetxController {
  final RxList<T> selectedItems;

  _MenuCheckController(List<T> initial)
      : selectedItems = RxList<T>.from(initial);

  void toggle(T item) {
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
  }
}

class SettingsMenuCheck<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> items;
  final List<T> initialSelection;
  final Future<List<T>> Function()? itemsProvider;
  final List<T> Function(List<T> providedItems)? initialSelectionProvider;
  final String Function(T item) itemToString;
  final Function(List<T> selectedItems)? onConfirm;
  final String? confirmText;
  final String? modalTitle;

  const SettingsMenuCheck({
    required this.title,
    required this.itemToString,
    this.items = const [],
    this.initialSelection = const [],
    this.itemsProvider,
    this.initialSelectionProvider,
    this.subtitle,
    this.onConfirm,
    this.confirmText,
    this.modalTitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayItemsCount = items.length;
    final displaySelectedCount = initialSelection.length;

    return SettingsTile(
      title: title,
      subtitle: subtitle,
      trailing: SettingsValueIndicator(
        value: '$displaySelectedCount/$displayItemsCount',
      ),
      onTap: () => _handleTap(context),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    List<T> menuItems;
    List<T> menuInitialSelection;
    if (itemsProvider != null) {
      SmartDialog.showLoading(msg: '');
      try {
        menuItems = await itemsProvider!();
        if (initialSelectionProvider != null) {
          menuInitialSelection = initialSelectionProvider!(menuItems);
        } else {
          menuInitialSelection = menuItems.toList();
        }
      } finally {
        SmartDialog.dismiss();
      }
    } else {
      menuItems = items;
      menuInitialSelection = initialSelection;
    }

    if (menuItems.isEmpty || !context.mounted) {
      return;
    }

    _openMenu(context, menuItems, menuInitialSelection);
  }

  void _openMenu(
    BuildContext context,
    List<T> items,
    List<T> initialSelection,
  ) {
    final controller = _MenuCheckController<T>(initialSelection);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDesignTokens.radius16),
          topRight: Radius.circular(AppDesignTokens.radius16),
        ),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                title: Text(
                  modalTitle?.tr ?? title.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  tooltip: confirmText?.tr ?? '确定',
                  onPressed: () {
                    Get.back();
                    onConfirm?.call(controller.selectedItems.toList());
                  },
                  icon: const Icon(Remix.delete_bin_line),
                ),
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      return Obx(
                        () => CheckboxListTile(
                          value: controller.selectedItems.contains(item),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(itemToString(item)),
                          onChanged: (selected) {
                            controller.toggle(item);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
