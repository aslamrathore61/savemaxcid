import 'package:flutter/services.dart';

class IconChanger {
  static const _channel = MethodChannel('com.savemax.cid/icon');

  static Future<void> switchIcon(String iconName) async {
    try {
      await _channel.invokeMethod('switchIcon', {'iconName': iconName});
    } on PlatformException catch (e) {
      print("Failed to switch icon: '${e.message}'.");
    }
  }
}
