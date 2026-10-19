import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:simple_live_app/app/utils/setting_gen_util.dart';


void main() {
  final source = File(p.join('lib', 'app', 'controller','app_settings_controller.dart'));
  final target = SettingGenUtil.generateForFile(source);
  print('Generated: ${target.path}');
}