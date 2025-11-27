// lib/screens/video_player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/user.dart';
import '../models/video.dart';
import '../services/api_client.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final AppUser currentUser;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.currentUser,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _api = ApiClient();
  YoutubePlayerController? _controller;
  Video? _video;
  bool _loading = true;
  Timer? _progressTimer;
  int _startSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final v = await _api.fetchVideoDetails(
        widget.videoId,
        widget.currentUser.id,
      );

      _startSeconds = v.progress?.positionSeconds ?? 0;

      final controller = YoutubePlayerController(
        initialVideoId: v.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
          controlsVisibleAtStart: true,
        ),
      );

      _controller = controller;
      _video = v;

      controller.addListener(() {
        // Seek only once after ready when we have progress
        if (controller.value.isReady &&
            _startSeconds > 0 &&
            controller.value.position.inSeconds < 2) {
          controller.seekTo(Duration(seconds: _startSeconds));
        }
      });

      _startProgressSyncTimer();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startProgressSyncTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncProgress();
    });
  }

  Future<void> _syncProgress() async {
    final c = _controller;
    final v = _video;
    if (c == null || v == null) return;
    if (!c.value.isReady) return;

    final pos = c.value.position.inSeconds;
    final total = v.durationSeconds > 0 ? v.durationSeconds : 1;
    final percent = (pos / total) * 100.0;

    try {
      await _api.sendVideoProgress(
        userId: widget.currentUser.id,
        videoId: v.videoId,
        positionSeconds: pos,
        completedPercent: percent.clamp(0, 100),
      );
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _controller == null || _video == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final video = _video!;

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.redAccent,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [

                player,

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (video.description != null &&
                            video.description!.trim().isNotEmpty)
                          Text(
                            video.description!,
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          const Text(
                            'No description available.',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
