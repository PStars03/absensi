# PRD.md — EduPresence Flutter Mobile + Supabase

## 1. Informasi Project

Nama aplikasi: EduPresence  
Jenis aplikasi: Aplikasi Mobile Absensi Biometrik & E-Learning  
Frontend: Flutter (stable), Dart SDK `^3.11.4` (Multi-platform)  
Backend & Database: Supabase (PostgreSQL)  
Database lokal/test: H2/SQLite (bawaan testing Flutter) atau Supabase Local Dev  
State Management: `setState` (Default MVP) — disiapkan untuk *scale* ke BLoC/Riverpod  
Face Recognition: `google_mlkit_face_detection`  
Autentikasi: Supabase Auth  
Penyimpanan File: Supabase Storage  
Logo utama: `edupresence-logo-horizontal.png`  
Logo ikon: `edupresence-logo-icon.png`  
Disusun oleh: Petrix Yoga Eka Pradivtia (NIM: 19241560, Kelas: 19.4A.18)  
Institusi: Universitas Bina Sarana Informatika - Sistem Informasi  

EduPresence adalah platform mobile terintegrasi untuk mendigitalisasi proses absensi siswa dan guru menggunakan *face recognition* serta menyediakan ekosistem e-learning terstruktur (materi, tugas, kuis) yang dikategorikan berdasarkan Mata Pelajaran (Mapel) atau Mata Kuliah.

## 2. Tujuan Produk

EduPresence dibuat untuk membantu sekolah:

1. Mengurangi kecurangan absensi dengan validasi *liveness detection* dan biometrik wajah, baik untuk tenaga pengajar maupun peserta didik.
2. Memudahkan siswa mendaftarkan akun secara mandiri, mengakses materi, dan mengumpulkan tugas langsung dari smartphone.
3. Memberikan alat bantu bagi guru untuk mendistribusikan dan mengoreksi tugas/kuis secara efisien berdasarkan jadwal dan mapel yang mereka ampu.
4. Sentralisasi data dengan *Row Level Security* (RLS) Supabase untuk mengamankan hak akses secara fundamental di level database.

## 3. Target Pengguna

### 3.1 Siswa
1. Register akun baru menggunakan Email, NISN, dan data kelas secara mandiri.
2. Login menggunakan Email/NISN yang telah didaftarkan.
3. Melakukan absensi masuk dan pulang via scan wajah.
4. Melihat jadwal pelajaran/kuliah.
5. Melihat dan mengunduh materi per mata pelajaran.
6. Mengunggah file jawaban tugas per mata pelajaran.
7. Mengerjakan kuis pilihan ganda atau isian.

### 3.2 Guru
1. Login menggunakan Email/NIP (Akun dibuat oleh Super Admin).
2. Melakukan absensi kehadiran mengajar (masuk dan pulang) via scan wajah di aplikasi.
3. **Melihat Jadwal Mengajar yang menampilkan daftar mapel/kelas yang diampu.**
4. Membuat materi dan slot tugas spesifik untuk setiap mata pelajaran.
5. Mengoreksi tugas siswa dan memberikan nilai/catatan per mata pelajaran.
6. Mengoreksi status absensi siswa secara manual (misal: dari Alpa menjadi Izin).
7. Membuat kuis (Pilihan Ganda & Isian) dan memberikan penilaian.

### 3.3 Super Admin
1. Login ke aplikasi.
2. Mengelola data master (Membuat akun Guru, verifikasi/manajemen Siswa).
3. **Menambahkan Guru dan menetapkan/memilih Mata Pelajaran (Mapel) yang akan diajarkan oleh guru tersebut saat pembuatan akun.**
4. Memiliki akses menyeluruh terhadap semua fitur Guru dan laporan kehadiran.

## 4. Role dan Hak Akses (Supabase RLS)

Manajemen hak akses menggunakan *Postgres Row Level Security* (RLS).

| Fitur | Siswa | Guru | Super Admin | RLS Policy Target |
|---|---:|---:|---:|---|
| Register Akun Baru | Ya | Tidak | Tidak | `Supabase Auth (Public)` |
| Absensi Scan Wajah | Ya | Ya | Tidak | `INSERT` (Siswa/Guru on `attendances`) |
| Melihat Jadwal Mapel | Ya | Ya | Ya | `SELECT` (Semua role on `schedules`) |
| Membuat Materi/Tugas (Per Mapel) | Tidak | Ya | Ya | `INSERT/UPDATE` (Guru/Admin) |
| Kumpul Tugas | Ya | Tidak | Tidak | `INSERT` (Siswa on `task_submissions`) |
| Assign Mapel ke Guru | Tidak | Tidak | Ya | `INSERT/UPDATE` (Admin on `schedules`) |
| Manajemen Akun | Tidak | Tidak | Ya | `ALL` (Admin on `profiles`) |

## 5. Modul Aplikasi

### 5.1 Autentikasi & Registrasi
1. Siswa dapat melakukan registrasi akun secara mandiri melalui aplikasi.
2. Saat penambahan Guru oleh Super Admin, terdapat form *dropdown/checkbox* untuk mengaitkan guru dengan Mata Pelajaran (Mapel) tertentu dan jadwalnya.

### 5.2 Presensi Biometrik Wajah
1. Mengaktifkan kamera depan untuk Guru dan Siswa.
2. Menjalankan *Liveness Check* via ML Kit.
3. Pencocokan vektor biometrik di sisi klien, kemudian data presensi di-*insert* ke tabel `attendances`.

### 5.3 Modul Jadwal Mengajar & Akses Kelas
Halaman jadwal mengajar dirancang menggunakan tata letak berbasis kartu (*card layout*) yang komprehensif.

1.  Sistem menampilkan daftar mapel dalam bentuk kartu berwarna.
2.  Setiap kartu memiliki header berwarna (seperti merah atau hijau) yang memuat nama mata pelajaran.
3.  Di bawah nama mata pelajaran, kartu memuat jadwal spesifik yang menampilkan hari dan rentang jam pelaksanaan.
4.  Isi kartu memuat atribut detail berupa Kode Dosen.
5.  Isi kartu juga menampilkan Kode MTK.
6.  Informasi SKS turut dicantumkan di dalam kartu.
7.  Kartu menyertakan informasi No Ruang pelaksanaan kelas.
8.  Atribut Kel Praktek tersedia sebagai pelengkap detail kelas.
9.  Atribut Kode Gabung ditampilkan di bagian isi kartu.
10. Pada bagian bawah kartu, terdapat tombol "Masuk Kelas" yang digunakan pengguna untuk masuk ke *dashboard* spesifik mata pelajaran tersebut.
11. Mengklik "Masuk Kelas" akan mengarahkan pengguna ke halaman spesifik mapel untuk mengakses **Materi, Tugas, dan Kuis** yang terisolasi khusus untuk mata pelajaran tersebut.

### 5.4 Modul Materi, Tugas & Kuis (Berbasis Mapel)
1. Seluruh materi, tugas, dan kuis sekarang diklasifikasikan secara ketat berdasarkan ID Mata Pelajaran (`subject_id`).
2. Guru membuat materi/tugas di dalam ruang "Masuk Kelas" sehingga data otomatis terikat dengan mapel terkait.
3. Siswa hanya dapat melihat tugas dan materi yang sesuai dengan mapel/jadwal yang mereka ikuti.

## 6. Frontend dan UI/UX

Gunakan desain *Material 3* yang rapi dan profesional.

| Nama | Hex | Penggunaan |
|---|---|---|
| Primary Blue | `#0F4C81` | Appbar, tombol utama, warna dominan |
| Card Header Red | `#B71C1C` | Header kartu mapel (seperti pada referensi jadwal) |
| Card Header Green| `#1B5E20` | Header kartu mapel alternatif |
| Success Green | `#28A745` | Teks Tepat Waktu, notifikasi berhasil |
| Warning Amber | `#FFC107` | Status Terlambat |

## 7. Persiapan Vibe Coding & Dependensi

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.14.2
  camera: ^0.10.5
  google_mlkit_face_detection: ^0.7.0
  file_picker: ^6.1.1
  intl: ^0.19.0