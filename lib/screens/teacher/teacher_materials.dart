import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/mock_data.dart';

/// Kelola Materi (Guru)
class TeacherMaterials extends StatelessWidget {
  const TeacherMaterials({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Materi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMaterial(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Materi'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockData.materials.length,
        itemBuilder: (context, index) {
          final m = MockData.materials[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryBlue),
              ),
              title: Text(m.title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(m.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(m.date, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
                onSelected: (v) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$v: ${m.title} (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMaterial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Tambah Materi', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: 'Judul Materi', prefixIcon: Icon(Icons.title_rounded))),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_rounded)), maxLines: 3),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Lampirkan File'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Materi ditambahkan (mock)'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
