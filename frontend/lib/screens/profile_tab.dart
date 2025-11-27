// lib/screens/tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../../services/session_manager.dart';
import '../../services/api_client.dart';
import '../../theme_controller.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback? onTestPushSent;

  const ProfileTab({
    super.key,
    required this.currentUser,
    this.onTestPushSent,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _api = ApiClient();
  final _testTitleCtrl = TextEditingController(text: 'Test push');
  final _testBodyCtrl =
  TextEditingController(text: 'Hello from StreamSync Lite');
  bool _sendingPush = false;

  @override
  void dispose() {
    _testTitleCtrl.dispose();
    _testBodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await SessionManager.clearSession();
    } catch (e, st) {
      debugPrint('Error clearing session: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear session. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _sendTestPush() async {
    setState(() {
      _sendingPush = true;
    });

    try {
      await _api.sendTestPush(
        userId: widget.currentUser.id,
        title: _testTitleCtrl.text.trim().isEmpty
            ? 'Test push'
            : _testTitleCtrl.text.trim(),
        body: _testBodyCtrl.text.trim().isEmpty
            ? 'Hello from StreamSync Lite'
            : _testBodyCtrl.text.trim(),
      );

      widget.onTestPushSent?.call();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test push requested successfully.')),
      );
    } catch (e, st) {
      debugPrint('Error sending test push: $e\n$st');
      if (!mounted) return;

      final msg = e.toString();

      String userMessage = 'Failed to send test push notification. Please try again.';

      if (msg.contains('429') ||
          msg.contains('Too many test pushes')) {
        userMessage =
        'Too many test pushes. Please wait a bit and try again.';
      } else if (msg.contains('404') ||
          msg.contains('User not found')) {
        userMessage =
        'Your account could not be found on the server. Please log in again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessage)),
      );

      if (msg.contains('404') || msg.contains('User not found')) {
        await Future.delayed(const Duration(milliseconds: 500));
        _logout();
      }
    } finally {
      if (mounted) {
        setState(() => _sendingPush = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),


        SwitchListTile(
          secondary: const Icon(Icons.dark_mode),
          title: const Text('Dark theme'),
          value: isDark,
          onChanged: (value) {
            themeController
                .setMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),

        const Divider(),


        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Test Push',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Text(
          'Send a test push notification to your own device via the backend.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _testTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _testBodyCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Body',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _sendingPush ? null : _sendTestPush,
            icon: _sendingPush
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.send),
            label: Text(_sendingPush ? 'Sending...' : 'Send Test Push'),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),


        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.redAccent),
          ),
          onTap: _logout,
        ),
      ],
    );
  }
}
