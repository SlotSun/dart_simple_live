import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HotKeyService extends GetxService {
  static HotKeyService get instance => Get.find<HotKeyService>();
  final Map<String, VoidCallback> _registry = {};
  var capture = false.obs;
  String curKey = '';

  // hotkey
  final Map<String, SingleActivator> hotKeyMap = {
    'hotKeyShowFollowFull': SingleActivator(
      LogicalKeyboardKey.period,
      alt: true,
      includeRepeats: false,
    ),
    'hotkeyShowSCListFull': SingleActivator(
      LogicalKeyboardKey.slash,
      alt: true,
      includeRepeats: false,
    ),
    'hotkeyShowSettingFull': SingleActivator(
      LogicalKeyboardKey.comma,
      alt: true,
      includeRepeats: false,
    ),
    'hotkeyShowMessagePanel': SingleActivator(
      LogicalKeyboardKey.f11,
      includeRepeats: false,
    ),
  };

  SingleActivator get hotKeyShowFollowFull => hotKeyMap['hotKeyShowFollowFull']!;

  SingleActivator get hotkeyShowSCListFull => hotKeyMap['hotkeyShowSCListFull']!;

  SingleActivator get hotkeyShowSettingFull => hotKeyMap['hotkeyShowSettingFull']!;

  SingleActivator get hotkeyShowMessagePanel => hotKeyMap['hotkeyShowMessagePanel']!;

  @override
  void onInit() {
    super.onInit();
    HardwareKeyboard.instance.addHandler(_handle);
  }

  // todo: user setting hot-key
  void hotKeyUserSet(KeyEvent event){
    // cur set key selected
    // event 2 SingleActivator
    // map[curKey] = activator
    // save
    // register
    // end
  }


  VoidCallback register(SingleActivator activator, VoidCallback onPressed) {
    final key = _encode(activator);
    _registry[key] = onPressed;
    // 闭包， key?.call() to unregister
    void cb() {
      // 路由栈 不会立刻 dispose
      if (_registry[key] == onPressed) {
        _registry.remove(key);
      }
    }

    return cb;
  }

  bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (capture.value) {
      //
      return false;
    }

    final key = _encodeFromEvent(event);
    if (key == null) {
      return false;
    }
    final callback = _registry[key];
    if (callback == null) {
      return false;
    }
    try {
      callback();
    } catch (e, s) {
      debugPrint('HotKey callback error: $e\n$s');
    }
    return true; // 已消费
  }

  SingleActivator? _toActivator(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return null;
    }

    final key = event.logicalKey;
    if (_isModifierKey(key)) {
      return null;
    }

    return SingleActivator(
      key,
      control: HardwareKeyboard.instance.isControlPressed,
      alt: HardwareKeyboard.instance.isAltPressed,
      shift: HardwareKeyboard.instance.isShiftPressed,
      meta: HardwareKeyboard.instance.isMetaPressed,
      includeRepeats: false,
    );
  }

  bool _isModifierKey(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.controlLeft ||
          k == LogicalKeyboardKey.controlRight ||
          k == LogicalKeyboardKey.altLeft ||
          k == LogicalKeyboardKey.altRight ||
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight ||
          k == LogicalKeyboardKey.metaLeft ||
          k == LogicalKeyboardKey.metaRight;

  String? _encodeFromEvent(KeyEvent event) {
    final parts = <String>[];
    // switch case
    if (HardwareKeyboard.instance.isControlPressed) {
      parts.add('ctrl');
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      parts.add('alt');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      parts.add('shift');
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      parts.add('meta');
    }
    parts.add(event.logicalKey.keyLabel.toLowerCase());
    return parts.join('+');
  }

  String _encode(SingleActivator a) {
    final parts = <String>[];
    if (a.control) {
      parts.add('ctrl');
    }
    if (a.alt) {
      parts.add('alt');
    }
    if (a.shift) {
      parts.add('shift');
    }
    if (a.meta) {
      parts.add('meta');
    }
    parts.add(a.trigger.keyLabel.toLowerCase());
    return parts.join('+');
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_handle);
    _registry.clear();
  }
}
