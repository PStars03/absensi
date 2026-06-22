import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

/// Manajemen Pengguna (Admin)
class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await SupabaseService.getProfilesByRole('teacher');
      final students = await SupabaseService.getProfilesByRole('student');
      
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pengguna: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins'),
          tabs: const [
            Tab(text: 'Guru'),
            Tab(text: 'Siswa'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUser(context),
        child: const Icon(Icons.person_add_rounded),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari pengguna...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _searchController.clear(),
                    ),
                  ),
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Guru tab
                    _buildUserList(_teachers, 'teacher'),
                    // Siswa tab
                    _buildUserList(_students, 'student'),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String role) {
    if (users.isEmpty) {
      return Center(child: Text('Belum ada data ${role == 'teacher' ? 'guru' : 'siswa'}'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final name = u['full_name'] ?? 'Tanpa Nama';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final identifier = u['identity_number'] ?? '-';
        final className = u['class_name'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
              ),
            ),
            title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['email'] ?? '', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                Text(
                  '${role == 'teacher' ? 'NIP' : 'NISN'}: $identifier${className != null ? ' • $className' : ''}',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'toggle', child: Text('Nonaktifkan')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) async {
                if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Hapus Pengguna?'),
                      content: Text('Yakin ingin menghapus $name?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await SupabaseService.deleteUserByAdmin(u['id']);
                      _fetchUsers();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil dihapus')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Aksi $v belum diimplementasikan'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddUser(BuildContext context) {
    String role = 'teacher';
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final identityCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String? errorMessage;
        bool showPassword = false;
        bool showConfirmPassword = false;
        
        return StatefulBuilder(
          builder: (modalContext, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    const Text('Tambah Pengguna', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'teacher', child: Text('Guru')),
                        DropdownMenuItem(value: 'student', child: Text('Siswa')),
                      ],
                      onChanged: (v) => setStateModal(() => role = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl, 
                      obscureText: !showPassword, 
                      decoration: InputDecoration(
                        labelText: 'Password', 
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setStateModal(() => showPassword = !showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl, 
                      obscureText: !showConfirmPassword, 
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password', 
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setStateModal(() => showConfirmPassword = !showConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: identityCtrl, decoration: InputDecoration(labelText: role == 'teacher' ? 'NIP' : 'NISN', prefixIcon: const Icon(Icons.badge_outlined))),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                            setStateModal(() => errorMessage = 'Harap lengkapi semua data');
                            return;
                          }
                          if (passCtrl.text != confirmPassCtrl.text) {
                            setStateModal(() => errorMessage = 'Password dan Konfirmasi Password tidak cocok');
                            return;
                          }
                          setStateModal(() {
                            isSaving = true;
                            errorMessage = null;
                          });
                          try {
                            await SupabaseService.createUserByAdmin(
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text,
                              fullName: nameCtrl.text.trim(),
                              role: role,
                              identityNumber: identityCtrl.text.trim(),
                            );
                            
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            _fetchUsers();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil ditambahkan')));
                          } catch (e) {
                            setStateModal(() {
                              isSaving = false;
                              errorMessage = 'Gagal menambah: $e';
                            });
                          }
                        },
                        child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
