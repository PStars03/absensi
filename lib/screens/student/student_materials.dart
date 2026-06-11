import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

/// Daftar Materi Siswa
class StudentMaterials extends StatelessWidget {
  const StudentMaterials({super.key});

  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': return Icons.description_rounded;
      case 'ppt': return Icons.slideshow_rounded;
      case 'video': return Icons.play_circle_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String type) {
    switch (type) {
      case 'pdf': return const Color(0xFFEF4444);
      case 'doc': return const Color(0xFF3B82F6);
      case 'ppt': return const Color(0xFFF59E0B);
      case 'video': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materi Pelajaran')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.materials.length,
        itemBuilder: (context, index) {
          final m = MockData.materials[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka: ${m.title}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _fileColor(m.fileType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_fileIcon(m.fileType), color: _fileColor(m.fileType), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(m.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(m.teacherName, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(m.date, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.download_rounded, color: AppColors.primaryBlue.withValues(alpha: 0.6), size: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
