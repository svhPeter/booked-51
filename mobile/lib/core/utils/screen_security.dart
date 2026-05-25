import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class ScreenSecurity {
  static const _channel = MethodChannel('com.aibuddy.docbook/security');

  static Future<void> enableScreenshotProtection() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableScreenshotProtection');
      }
    } catch (_) {}
  }

  static Future<void> disableScreenshotProtection() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableScreenshotProtection');
      }
    } catch (_) {}
  }

  static bool isScreenRecordingSupported() {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
}
