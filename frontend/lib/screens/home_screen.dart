// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:streamsync_lite/screens/profile_tab.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'downloads_tab.dart';
import 'feed_tab.dart';
import 'notifications_tab.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  int _unreadCount = 0;
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _refreshUnreadFromServer();
  }

  Future<void> _refreshUnreadFromServer() async {
    try {
      final list =
      await _api.fetchNotifications(widget.currentUser.id);
      final unread =
          list.where((n) => !n.isRead && !n.deleted).length;
      if (!mounted) return;
      setState(() {
        _unreadCount = unread;
      });
    } catch (_) {

    }
  }

  void _handleUnreadChanged(int count) {
    setState(() {
      _unreadCount = count;
    });
  }

  void _handleTestPushSent() {
    _refreshUnreadFromServer();
  }

  String _badgeText() {
    if (_unreadCount <= 0) return '';
    if (_unreadCount > 9) return '9+';
    return '$_unreadCount';
  }

  Widget _buildNotifIcon(IconData icon) {
    if (_unreadCount <= 0) {
      return Icon(icon);
    }
    final text = _badgeText();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 16,
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FeedTab(currentUser: widget.currentUser),
      DownloadsTab(currentUser: widget.currentUser),
      NotificationsTab(
        currentUser: widget.currentUser,
        onUnreadChanged: _handleUnreadChanged,
      ),
      ProfileTab(
        currentUser: widget.currentUser,
        onTestPushSent: _handleTestPushSent,
      ),
    ];

    final titles = ['Home', 'Downloads', 'Notifications', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        centerTitle: false,
      ),
      body: tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: _buildNotifIcon(Icons.notifications_outlined),
            activeIcon: _buildNotifIcon(Icons.notifications),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
