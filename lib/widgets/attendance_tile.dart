import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tile item absensi dengan status badge berwarna
class AttendanceTile extends StatelessWidget {
  final String name;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status; // 'hadir', 'terlambat', 'alpa', 'izin'
  final VoidCallback? onTap;
  final VoidCallback? onEditStatus;

  const AttendanceTile({
    super.key,
    required this.name,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.onTap,
    this.onEditStatus,
  });

  Color get _statusColor {
    switch (status) {
      case 'hadir':
        return AppColors.success;
      case 'terlambat':
        return AppColors.warning;
      case 'alpa':
        return AppColors.error;
      case 'izin':
        return const Color(0xFF6B7280);
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _statusBgColor {
    switch (status) {
      case 'hadir':
        return AppColors.successLight;
      case 'terlambat':
        return AppColors.warningLight;
      case 'alpa':
        return AppColors.errorLight;
      case 'izin':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'alpa':
        return 'Alpa';
      case 'izin':
        return 'Izin';
      default:
        return status;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'hadir':
        return Icons.check_circle_rounded;
      case 'terlambat':
        return Icons.schedule_rounded;
      case 'alpa':
        return Icons.cancel_rounded;
      case 'izin':
        return Icons.info_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.login_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (checkOut != null && checkOut != '-') ...[
                          const SizedBox(width: 8),
                          Icon(Icons.logout_rounded, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            checkOut!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 14, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit button (for teachers)
              if (onEditStatus != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onEditStatus,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
