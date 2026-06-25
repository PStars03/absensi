# Widget Tree: Fitur Siswa (Student)

Berikut adalah hierarki *Widget Tree* untuk layar Siswa dengan penerapan MVC (menggunakan `StudentController`).

## 1. Student Dashboard View (`student_dashboard.dart`)
- `Scaffold`
  - `SafeArea`
    - `RefreshIndicator`
      - `SingleChildScrollView`
        - `Padding`
          - `Column`
            - `Row` (Header Profile)
              - `CircleAvatar` (Foto Profil Wajah)
              - `Column` (Nama & NIS)
              - `StreamBuilder` (Lonceng Notifikasi)
                - `Badge` (Jumlah Belum Dibaca)
                  - `IconButton` (Ke Halaman Notifikasi)
            - `SizedBox`
            - `Row`
              - `StatCard` (Kehadiran)
              - `StatCard` (Sakit/Izin)
              - `StatCard` (Alpa)
            - `SizedBox`
            - `Text` ("Jadwal Hari Ini")
            - `FutureBuilder` (Mengambil Jadwal dari Controller)
              - `ListView.builder`
                - `Card` (Item Jadwal)
                  - `ListTile`
                  - `ElevatedButton` ("Masuk Kelas" -> Buka Face Scan)
  - `BottomNavigationBar` (`AppBottomNav` role: student)

---

## 2. Notifications View (`notifications_screen.dart`)
- `Scaffold`
  - `AppBar` ("Notifikasi")
  - `StreamBuilder` (Memantau tabel notifications secara real-time)
    - `ListView.builder`
      - `Card`
        - `ListTile`
          - `Icon` (Task/Material)
          - `Text` (Judul & Pesan)
          - `IconButton` (Delete Notification)
