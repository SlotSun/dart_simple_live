import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_live_app/widgets/status/app_status_panel.dart';

class AppEmptyWidget extends StatelessWidget {
  final Function()? onRefresh;

  const AppEmptyWidget({this.onRefresh, super.key});

  @override
  Widget build(BuildContext context) {
    return AppStatusPanel(
      visual: ExcludeSemantics(
        child: LottieBuilder.asset(
          'assets/lotties/empty.json',
          width: 144,
          height: 112,
          fit: BoxFit.contain,
          repeat: false,
          animate: !MediaQuery.of(context).disableAnimations,
        ),
      ),
      title: '这里什么都没有',
      message: onRefresh == null ? null : '可以刷新后再试一次',
      actionLabel: onRefresh == null ? null : '刷新',
      onRefresh: onRefresh,
    );
  }
}
