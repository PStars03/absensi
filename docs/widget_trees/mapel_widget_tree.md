# Widget Tree: Fitur Kelas & Guru (Teacher/Mapel)

Berikut adalah hierarki *Widget Tree* untuk interaksi di dalam kelas (Guru & Siswa) menggunakan MVC (`MapelController`).

## 1. Mapel Dashboard View (`mapel_dashboard.dart`)
- `Scaffold`
  - `AppBar` (Nama Mata Pelajaran)
    - `IconButton` (Buka Scanner Absen Wajah) -> *Khusus Siswa jika Guru sudah absen*
  - `Column`
    - `TabBar` (Materi | Tugas | Absensi | Jurnal)
    - `Expanded`
      - `TabBarView`
        
        **A. Tab Materi (`_buildMateriTab`)**
        - `ListView.builder`
          - `Card` (File URL, Judul, Deskripsi)
        - `FloatingActionButton` (Tambah Materi) -> *Khusus Guru*

        **B. Tab Tugas (`_buildTugasTab`)**
        - `ListView.builder`
          - `Card` (Tenggat Waktu, File URL)
            - `ElevatedButton` ("Kumpulkan Tugas") -> *Khusus Siswa*
        - `FloatingActionButton` (Tambah Tugas) -> *Khusus Guru*

        **C. Tab Absensi (`_buildAbsensiTab`)**
        - `ListView.builder`
          - `ListTile` (Nama Siswa, Jam Hadir, Lokasi GPS)
            - `Chip` (Status: Hadir/Terlambat/Alpa)
        - `FloatingActionButton` ("Selesai & Rekap") -> *Khusus Guru menutup kelas*

        **D. Tab Jurnal (`_buildJurnalTab`)**
        - `ListView.builder`
          - `Card` (Rangkuman Pertemuan)
        - `ElevatedButton` ("Isi Rangkuman") -> *Khusus Guru*

---

## 2. Face Scan View (`face_scan_screen.dart`)
- `Scaffold`
  - `Stack`
    - `CameraPreview` (Tampilan Kamera Depan secara langsung)
    - `CustomPaint` (Kotak pemindai wajah mendeteksi landmark ML Kit)
    - `Positioned` (Teks Instruksi: "Arahkan wajah Anda ke dalam bingkai")
    - `Positioned` (Tombol Batal)
    - `Positioned` (Indikator Loading Pengenalan TFLite)
