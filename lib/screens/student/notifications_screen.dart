import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }

      // Mark all as read
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
          
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat notifikasi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi.', style: TextStyle(fontFamily: 'Poppins')))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] == true;
                    final date = DateTime.parse(notif['created_at']).toLocal();
                    final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(date);

                    IconData icon;
                    Color color;
                    switch (notif['type']) {
                      case 'materi':
                        icon = Icons.menu_book_rounded;
                        color = AppColors.primaryBlue;
                        break;
                      case 'tugas':
                      case 'deadline':
                        icon = Icons.assignment_rounded;
                        color = AppColors.warning;
                        break;
                      default:
                        icon = Icons.notifications_rounded;
                        color = Colors.grey;
                    }

                    return Container(
                      color: isRead ? Colors.transparent : AppColors.primaryBlue.withValues(alpha: 0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notif['message'] ?? '', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                        isThreeLine: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
    );
  }
}
