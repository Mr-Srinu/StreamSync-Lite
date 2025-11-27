// lib/screens/tabs/downloads_tab.dart
import 'package:flutter/material.dart';
import 'package:streamsync_lite/screens/video_player_screen.dart';
import 'package:streamsync_lite/screens/widgets/video_card.dart';

import '../../models/video.dart';
import '../../models/user.dart';
import '../services/download_services.dart';

class DownloadsTab extends StatefulWidget {
  final AppUser currentUser;

  const DownloadsTab({super.key, required this.currentUser});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<DownloadsTab> {
  List<Video> _downloads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _loading = true;
    });
    final list = await DownloadService.loadDownloads();
    if (!mounted) return;
    setState(() {
      _downloads = list;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await _loadDownloads();
  }

  Future<void> _removeDownload(Video v) async {
    await DownloadService.remove(v.videoId);
    await _loadDownloads();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed "${v.title}" from cache')),
    );
  }

  Future<void> _clearCache() async {
    if (_downloads.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text(
            'This will remove all cached video metadata. You can still stream videos from Home.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DownloadService.clearAll();
    await _loadDownloads();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared cached videos')),
    );
  }

  Widget _buildHeaderCard() {
    final count = _downloads.length;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: ListTile(
        leading: const Icon(Icons.download_done),
        title: const Text('Cached videos'),
        subtitle: Text(
          count == 0
              ? 'No cached videos yet. Long press a video in Home to save.'
              : '$count video${count == 1 ? '' : 's'} cached for quick access.',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Clear cache',
          onPressed: count == 0 ? null : _clearCache,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _downloads.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 120),
          const Center(
            child: Text(
              'No cached videos.\nLong press on a video in Home to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      )
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: _downloads.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderCard();
          }
          final v = _downloads[index - 1];
          return Dismissible(
            key: ValueKey(v.videoId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              child:
              const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              _removeDownload(v);
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8),
              child: VideoCard(
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
              ),
            ),
          );
        },
      ),
    );
  }
}
