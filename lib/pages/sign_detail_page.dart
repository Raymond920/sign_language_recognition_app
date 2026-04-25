import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';
import 'dart:async';

class SignDetailPage extends StatefulWidget {
  const SignDetailPage({super.key, required this.sign});

  final Sign sign;

  @override
  State<SignDetailPage> createState() => _SignDetailPageState();
}

class _SignDetailPageState extends State<SignDetailPage> {
  late Stream<List<ConnectivityResult>> _connectivityStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  late YoutubePlayerController _controller;
  int _currentVolume = 100;
  int _lastVolume = 100;
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();

    _connectivityStream = Connectivity().onConnectivityChanged;

    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = _hasConnection(results);
      });
    });

    _connectivitySubscription = _connectivityStream.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = _hasConnection(results);
      });
    });

    _controller = YoutubePlayerController(
      initialVideoId: widget.sign.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: SettingsService.cachedAutoplay,
        mute: false,
        disableDragSeek: false,
        loop: true,
        isLive: false,
        forceHD: true,
        enableCaption: false,
        hideControls: true,
        controlsVisibleAtStart: false,
      ),
    );

    // Listen only to isPlaying changes to update button UI, not volume or other state
    _controller.addListener(_onPlayerStateChanged);

    _currentVolume = _controller.value.volume;
    _lastVolume = _currentVolume > 0 ? _currentVolume : 100;
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    // Trigger rebuild so button reflects current play state
    setState(() {});
  }

  Future<void> _handlePlayPausePress() async {
    // Prevent rapid clicks while player is not ready or buffering during loop transition.
    final value = _controller.value;
    if (!_isButtonEnabled ||
        !value.isReady ||
        value.playerState == PlayerState.buffering) {
      return;
    }

    setState(() {
      _isButtonEnabled = false;
    });

    try {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }

    // Re-enable button after a brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isButtonEnabled = true;
      });
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildOfflineState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 40),
          const SizedBox(height: 12),
          Text(
            'No Internet Connection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Video unavailable while offline.'),
        ],
      ),
    );
  }

  Widget _buildMissingVideoState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_library_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'No Tutorial Video',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('This sign does not have a YouTube video yet.'),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.all(0),
          icon: const Icon(Icons.replay),
          iconSize: 30,
          tooltip: 'Replay',
          onPressed: () {
            _controller.seekTo(
              _controller.value.position -
                  const Duration(seconds: 10),
            );
          },
        ),
        SizedBox(width: 10),
        IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(
            _controller.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
          ),
          iconSize: 40,
          tooltip: _controller.value.isPlaying
                      ? 'Pause'
                      : 'Play',
          onPressed: _isButtonEnabled
              ? _handlePlayPausePress
              : null,
        ),
        SizedBox(width: 10),
        IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(
            _currentVolume == 0
                ? Icons.volume_off
                : Icons.volume_up,
          ),
          iconSize: 30,
          tooltip: _currentVolume != 0 ? 'Mute' : 'Unmuted',
          onPressed: () {
            if (_currentVolume == 0) {
              // It's currently muted, so unmute to the last non-zero volume
              _controller.setVolume(_lastVolume);
              setState(() {
                _currentVolume = _lastVolume;
              });
            } else {
              // It's currently unmuted, so mute (set volume to 0)
              _lastVolume =
                  _currentVolume; // Remember the current volume before muting
              _controller.setVolume(0);
              setState(() {
                _currentVolume = 0;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildReferenceImage(String imagePath){
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference Image', style: Theme.of(context).textTheme.titleMedium
          ),
          SizedBox(height: 10),
          Center(
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.asset(
                imagePath
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(List<String> instructions){
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to perform this sign', style: Theme.of(context).textTheme.titleMedium
          ),
          SizedBox(height: 16),
          ...instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary, // or your theme color
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      softWrap: true,
                      style: TextStyle(
                        color: isDark ? colorScheme.onSurface : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final hasVideoId = widget.sign.videoId.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.sign.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                border: Border.all(
                  color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isOnline)
                    _buildOfflineState(context)
                  else if (!hasVideoId)
                    _buildMissingVideoState(context)
                  else
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: YoutubePlayer(
                            aspectRatio: 4/3,
                            controller: _controller,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.blueAccent,
                            progressColors: const ProgressBarColors(
                              playedColor: Colors.blue,
                              handleColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildVideoControls()
                      ],
                    ),
                  
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildReferenceImage(widget.sign.imagePath),
            SizedBox(height: 20),
            _buildInstructionCard(widget.sign.instructions),
          ],
        ),
      ),
    );
  }
}
