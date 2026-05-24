import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'audio_helper_stub.dart';

class AudioHelperImpl implements AudioHelper {
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  Completer<List<int>?>? _stopCompleter;
  html.AudioElement? _audioElement;
  StreamSubscription? _timeUpdateSub;
  StreamSubscription? _endedSub;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      stream?.getTracks().forEach((track) => track.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    _recordedChunks.clear();
    final stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
    if (stream == null) return;

    _mediaRecorder = html.MediaRecorder(stream);
    _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
      final html.BlobEvent blobEvent = event as html.BlobEvent;
      if (blobEvent.data != null) {
        _recordedChunks.add(blobEvent.data!);
      }
    });

    _mediaRecorder!.addEventListener('stop', (html.Event event) async {
      final blob = html.Blob(_recordedChunks, 'audio/webm');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoadEnd.first;
      final Uint8List bytes = reader.result as Uint8List;

      // Stop all tracks to release the mic icon in tab
      stream.getTracks().forEach((track) => track.stop());

      _stopCompleter?.complete(bytes.toList());
    });

    _mediaRecorder!.start();
  }

  @override
  Future<List<int>?> stopRecording() async {
    if (_mediaRecorder == null) return null;
    _stopCompleter = Completer<List<int>?>();
    _mediaRecorder!.stop();
    return _stopCompleter!.future;
  }

  @override
  void cancelRecording() {
    if (_mediaRecorder != null) {
      _mediaRecorder!.stop();
      _mediaRecorder = null;
    }
  }

  @override
  void play(String url, {required VoidCallback onComplete, required Function(double progress, double duration) onProgress}) {
    stop();

    _audioElement = html.AudioElement(url);
    _timeUpdateSub = _audioElement!.onTimeUpdate.listen((event) {
      final duration = _audioElement!.duration.toDouble();
      final current = _audioElement!.currentTime.toDouble();
      if (duration > 0) {
        onProgress(current / duration, duration);
      }
    });

    _endedSub = _audioElement!.onEnded.listen((event) {
      stop();
      onComplete();
    });

    _audioElement!.play();
  }

  @override
  void stop() {
    _timeUpdateSub?.cancel();
    _timeUpdateSub = null;
    _endedSub?.cancel();
    _endedSub = null;
    if (_audioElement != null) {
      _audioElement!.pause();
      _audioElement = null;
    }
  }

  @override
  void dispose() {
    stop();
  }
}
