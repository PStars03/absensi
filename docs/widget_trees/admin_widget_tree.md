# Widget Tree: Fitur Admin

Berikut adalah hierarki *Widget Tree* untuk fitur dasbor Administrator. Pola yang digunakan adalah MVC, di mana tampilan (*View*) hanya bertugas menggambar UI dan menerima *State* dari `AdminController`.

## 1. Admin Dashboard View (`admin_dashboard.dart`)
- `Scaffold`
  - `AppBar` (Custom dengan Icon & Title)
  - `RefreshIndicator` (Untuk memuat ulang data)
    - `SingleChildScrollView`
      - `Padding`
        - `Column`
          - `Row` (Welcome Text & Date)
          - `SizedBox`
          - `Row`
            - `StatCard` (Total Siswa)
            - `StatCard` (Total Guru)
            - `StatCard` (Total Kelas)
          - `SizedBox`
          - `Text` ("Aksi Cepat")
          - `GridView`
            - `ActionCard` (Kelola Pengguna)
            - `ActionCard` (Jadwal Pelajaran)
            - `ActionCard` (Kelola Kelas)
            - `ActionCard` (Laporan)
            - `ActionCard` (Pengaturan GPS Radius)
          - `SizedBox`
          - `Text` ("Aktivitas Jadwal Hari Ini")
          - `ListView.builder` (Daftar jadwal)
            - `ActivityItem` (Tile Jadwal)
  - `BottomNavigationBar` (`AppBottomNav` role: admin)

---

## 2. Admin Users View (`admin_users.dart`)
- `Scaffold`
  - `AppBar` ("Kelola Pengguna")
  - `Column`
    - `TabBar` (Siswa | Guru)
    - `Expanded`
      - `TabBarView`
        - `ListView` (Daftar Siswa)
          - `UserTile` (Menampilkan foto wajah, NIS, dan status)
            - `IconButton` (Hapus/Nonaktifkan Pengguna)
        - `ListView` (Daftar Guru)
          - `UserTile` (Menampilkan NIP dan status)
