# EduPresence
## Smart Attendance, Learning Management & Academic Information System

Version: 2.0 Enterprise
Platform: Flutter + Supabase
Target: SMK/SMA Sederajat

### Disusun Oleh
Petrix Yoga Eka Pradivtia
NIM: 19241560
Program Studi Sistem Informasi
Universitas Bina Sarana Informatika

---

# 1. PRODUCT OVERVIEW

EduPresence adalah platform digital sekolah terintegrasi yang menggabungkan:
- Face Recognition Attendance System
- Learning Management System (LMS)
- Academic Information System (AIS)
- Student Monitoring System
- Teacher Management System
- School Administration System

---

# 2. BUSINESS OBJECTIVES

## Tujuan Utama
- Menghilangkan absensi manual
- Mencegah titip absen
- Digitalisasi sekolah SMK/SMA
- Sentralisasi materi, tugas, dan kuis
- Monitoring siswa real-time

---

# 3. TECHNOLOGY STACK

## Frontend
- Flutter Stable
- Dart SDK ^3.11.4
- Android
- iOS
- Web
- Windows
- Linux
- macOS

## Backend
- Supabase Auth
- PostgreSQL
- Realtime
- Storage
- Edge Functions
- RLS

---

# 4. USER ROLES

## Student
- Registrasi akun
- Login
- Face enrollment
- Absensi wajah
- Materi
- Tugas
- Kuis
- Nilai

## Teacher
- Kelola materi
- Kelola tugas
- Kelola kuis
- Penilaian
- Validasi absensi

## Wali Kelas
- Monitoring siswa
- Rekap absensi
- Rekap nilai

## Super Admin
- Full access sistem

---

# 5. FACE ATTENDANCE

## Flow
1. Buka menu absensi
2. Kamera aktif
3. Face Detection
4. Liveness Check
5. Face Matching
6. GPS Validation
7. Simpan absensi

---

# 6. LMS MODULE

## Materi
- Upload PDF
- Upload PPT
- Upload Video
- Download Materi

## Tugas
- Upload Tugas
- Penilaian
- Feedback

## Kuis
- Multiple Choice
- Short Answer
- Essay

---

# 7. DATABASE

## profiles
- id
- email
- full_name
- role

## students
- id
- profile_id
- class_id
- nis
- face_embedding

## teachers
- id
- profile_id
- nip

## subjects
- id
- code
- name

## schedules
- id
- subject_id
- teacher_id
- class_id

## attendance
- id
- student_id
- subject_id
- timestamp
- status

---

# 8. SECURITY

- HTTPS Only
- JWT Authentication
- Face Embedding Encryption
- Row Level Security

---

# 9. UI/UX

## Material 3

Primary: #0F4C81
Success: #28A745
Warning: #FFC107
Danger: #B71C1C

---

# 10. ROADMAP

## Phase 1
- Authentication
- Face Attendance
- Jadwal

## Phase 2
- Materi
- Tugas

## Phase 3
- Kuis
- Penilaian

## Phase 4
- Monitoring
- Admin Panel

---

# TAGLINE

"Hadir, Belajar, Berkembang, dan Berprestasi dalam Satu Platform Digital."
