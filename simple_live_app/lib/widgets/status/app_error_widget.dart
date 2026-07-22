import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_live_app/widgets/status/app_status_panel.dart';

class AppErrorWidget extends StatelessWidget {
  final Function()? onRefresh;
  final String errorMsg;

  const AppErrorWidget({
    this.errorMsg = '',
    this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppStatusPanel(
      visual: ExcludeSemantics(
        child: LottieBuilder.asset(
          'assets/lotties/error.json',
          width: 156,
          height: 112,
          fit: BoxFit.contain,
          repeat: false,
          animate: !MediaQuery.of(context).disableAnimations,
        ),
      ),
      title: '加载失败',
      message: errorMsg.isEmpty ? '请稍后再试' : errorMsg,
      actionLabel: onRefresh == null ? null : '重新加载',
      onRefresh: onRefresh,
    );
  }
}
