import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> get _notificationsStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Tandai Semua Dibaca',
            onPressed: () async {
              await SupabaseService.markAllNotificationsAsRead();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text('Tidak ada notifikasi saat ini.', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['is_read'] ?? false;
              final dateStr = notif['created_at'] as String;
              final date = DateTime.parse(dateStr).toLocal();
              
              final timeFormatter = DateFormat('HH:mm');
              final dateFormatter = DateFormat('dd MMM yyyy');
              final timeString = '${timeFormatter.format(date)} - ${dateFormatter.format(date)}';

              IconData icon;
              Color color;
              switch (notif['type']) {
                case 'task':
                  icon = Icons.assignment_rounded;
                  color = AppColors.warning;
                  break;
                case 'material':
                  icon = Icons.menu_book_rounded;
                  color = AppColors.primaryBlue;
                  break;
                default:
                  icon = Icons.notifications_rounded;
                  color = AppColors.primaryBlue;
              }

              return Dismissible(
                key: Key(notif['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  try {
                    await SupabaseService.deleteNotification(notif['id']);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
                  }
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: isRead ? Colors.white : AppColors.primaryBlue.withValues(alpha: 0.05),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      notif['title'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif['message'] ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!(notif['is_read'] ?? false)) {
                        await _supabase.from('notifications').update({'is_read': true}).eq('id', notif['id']);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
