import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/screen_security.dart';

class VideoCallScreen extends StatefulWidget {
  final String appId;
  final String channelName;
  final String token;
  final int uid;
  final bool isMock;
  final String appointmentId;

  const VideoCallScreen({
    super.key,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.isMock,
    required this.appointmentId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isConnecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      ScreenSecurity.enableScreenshotProtection();
    }
    if (kIsWeb) {
      _isConnecting = false;
    } else if (widget.isMock) {
      _initMock();
    } else {
      _initAgora();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      ScreenSecurity.disableScreenshotProtection();
    }
    _cleanup();
    super.dispose();
  }

  Future<void> _initMock() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _initAgora() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _requestPermissions();
      }

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: widget.appId));

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() => _isConnecting = false);
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() => _remoteUid = null);
          }
        },
        onError: (error, description) {
          if (mounted) {
            setState(() => _error = 'Agora error: ${error.name}');
            _isConnecting = false;
          }
        },
      ));

      await engine.enableVideo();
      await engine.startPreview();

      _engine = engine;

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to join: $e';
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    final perms = [
      Permission.camera,
      Permission.microphone,
    ];
    for (final p in perms) {
      final status = await p.request();
      if (status.isDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.toString().split(".").last} permission denied'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _cleanup() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        _engine!.release();
      } catch (_) {}
      _engine = null;
    }
  }

  Future<void> _toggleMic() async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(_isMicOn);
    }
    if (mounted) setState(() => _isMicOn = !_isMicOn);
  }

  Future<void> _toggleCamera() async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(_isCameraOn);
    }
    if (mounted) setState(() => _isCameraOn = !_isCameraOn);
  }

  Future<void> _switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  Future<void> _endCall() async {
    await _cleanup();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebFallback();
    return Scaffold(
      body: Stack(
        children: [
          if (_error != null)
            _buildError()
          else if (widget.isMock)
            _buildMockVideo()
          else if (_engine != null)
            _buildAgoraVideo()
          else
            _buildPlaceholder(),
          _buildControls(),
          _buildHeader(),
          if (_isConnecting) _buildConnectingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAgoraVideo() {
    return Stack(
      children: [
        if (_remoteUid != null)
          _buildRemoteVideo()
        else
          _buildWaiting(),
        Positioned(
          right: 16,
          top: 100,
          width: 120,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteVideo() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid!),
        connection: RtcConnection(
          channelId: widget.channelName,
          localUid: widget.uid,
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'Waiting for other participant...',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _endCall,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  size: 72,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Mobile-Only Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Video consultations are currently available on the DocBook mobile app.\n\n'
                'Please open this appointment on your iOS or Android device to join the video call.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _endCall,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockVideo() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: const Text(
              'SIMULATED VIDEO CALL (DEV MODE)',
              style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
          const Icon(Icons.videocam, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Channel: ${widget.channelName}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'UID: ${widget.uid}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Initializing...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _endCall,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave Call', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Connecting...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _endCall,
              ),
              const Spacer(),
              Text(
                widget.isMock ? 'DEV CALL' : 'Video Call',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _isMicOn ? Icons.mic : Icons.mic_off,
                onTap: _toggleMic,
              ),
              _ControlButton(
                icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                onTap: _toggleCamera,
              ),
              _ControlButton(
                icon: Icons.call_end,
                color: Colors.red,
                iconColor: Colors.white,
                onTap: _endCall,
              ),
              _ControlButton(
                icon: Icons.switch_camera,
                onTap: _switchCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      ),
    );
  }
}
