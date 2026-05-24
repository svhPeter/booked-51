import 'package:flutter/foundation.dart';

abstract class AudioHelper {
  factory AudioHelper.create() => AudioHelperImpl();

  Future<void> init();
  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<List<int>?> stopRecording(); // Returns the raw audio bytes
  void cancelRecording();
  void play(String url, {required VoidCallback onComplete, required Function(double progress, double duration) onProgress});
  void stop();
  void dispose();
}

class AudioHelperImpl implements AudioHelper {
  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> startRecording() async {}

  @override
  Future<List<int>?> stopRecording() async => null;

  @override
  void cancelRecording() {}

  @override
  void play(String url, {required VoidCallback onComplete, required Function(double progress, double duration) onProgress}) {}

  @override
  void stop() {}

  @override
  void dispose() {}
}
