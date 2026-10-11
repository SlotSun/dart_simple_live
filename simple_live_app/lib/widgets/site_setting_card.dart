import 'package:material_ui/material_ui.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/account.dart';
import 'package:simple_live_app/widgets/net_image.dart';

/// 账号设置项：展示账号信息，点击跳转到登录详情页
///
/// 类似 [LiveRoomCard] 的角色——只负责展示和跳转，不处理业务逻辑
class SiteSettingCard extends StatelessWidget {
  final Account account;
  final Function() onTap;

  const SiteSettingCard(this.account, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final site = Sites.allSites[account.siteId]!;
    final logined = account.isActive;
    return ListTile(
      leading: logined && account.avatar?.isNotEmpty == true
          ? NetImage(account.avatar!, width: 36, height: 36, borderRadius: 18)
          : Image.asset(site.logo, width: 36, height: 36),
      title: Text(site.name),
      subtitle: Text(account.userName ?? "未登录"),
      trailing: logined ? const Icon(Icons.logout) : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
