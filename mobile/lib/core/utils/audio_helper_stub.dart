import 'package:flutter/foundation.dart';

abstract class AudioHelper {
  static AudioHelper create() {
    throw UnsupportedError('Cannot create an AudioHelper without conditional imports');
  }

  Future<void> init();
  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<List<int>?> stopRecording(); // Returns the raw audio bytes
  void cancelRecording();
  void play(String url, {required VoidCallback onComplete, required Function(double progress, double duration) onProgress});
  void stop();
  void dispose();
}
