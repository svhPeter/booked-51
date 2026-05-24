import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_helper_stub.dart';

class AudioHelperImpl implements AudioHelper {
  Timer? _simulatedTimer;
  double _duration = 3.0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async {
    return true;
  }

  @override
  Future<void> startRecording() async {}

  @override
  Future<List<int>?> stopRecording() async {
    // Return dummy M4A bytes
    return [0, 0, 0, 16, 102, 116, 121, 112, 77, 52, 65, 32];
  }

  @override
  void cancelRecording() {}

  @override
  void play(String url, {required VoidCallback onComplete, required Function(double progress, double duration) onProgress}) {
    stop();
    
    double progress = 0.0;
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      progress += 0.1 / _duration;
      if (progress >= 1.0) {
        onProgress(1.0, _duration);
        stop();
        onComplete();
      } else {
        onProgress(progress, _duration);
      }
    });
  }

  @override
  void stop() {
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
  }

  @override
  void dispose() {
    stop();
  }
}
