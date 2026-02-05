import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';

class AppAnalyticsObserver extends NavigatorObserver {

  static AppAnalyticsObserver get observer => AppAnalyticsObserver();

  void _log(Route<dynamic>? route) {
    if (route == null) return;

    if (!AppSettingsController.instance.firebaseEnable.value) {
      return;
    }

    final name = route.settings.name;
    if (name == null) return;

    FirebaseAnalytics.instance.logScreenView(
      screenName: name,
      screenClass: name,
    );
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _log(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _log(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _log(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
