// lib/screens/tabs/feed_tab.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streamsync_lite/screens/video_player_screen.dart';
import 'package:streamsync_lite/screens/widgets/video_card.dart';
import '../../models/user.dart';
import '../../models/video.dart';
import '../../services/api_client.dart';
import '../services/download_services.dart';
import '../services/favorites_services.dart';


class FeedTab extends StatefulWidget {
  final AppUser currentUser;

  const FeedTab({super.key, required this.currentUser});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _api = ApiClient();
  late Future<List<Video>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchLatestVideos();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.fetchLatestVideos();
    });
    await _future;
  }

  void _showVideoActions(Video video) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Save for offline'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DownloadService.add(video);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to Downloads'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Add to favourites'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await FavoritesService.add(video.videoId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to favourites'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final url =
                      'https://www.youtube.com/watch?v=${video.videoId}';
                  Share.share(url);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Video>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('No videos yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoCard(
                video: v,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videoId: v.videoId,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
                onLongPress: () => _showVideoActions(v),
              );
            },
          );
        },
      ),
    );
  }
}
