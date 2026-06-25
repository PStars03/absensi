# Widget Tree: Fitur Autentikasi (Auth)

Berikut adalah hierarki *Widget Tree* untuk fitur Autentikasi (Login & Register) yang mengadopsi pola MVC (berkomunikasi dengan `AuthController`).

## 1. Login View (`login_screen.dart`)
- `Scaffold`
  - `SafeArea`
    - `SingleChildScrollView`
      - `Container` (Background / Box Decoration)
        - `Padding`
          - `Column`
            - `Row` (Logo & Title)
              - `Image`
              - `Text` ("EduPresence")
            - `SizedBox`
            - `Text` ("Selamat Datang Kembali")
            - `Text` ("Masuk untuk melanjutkan presensi")
            - `Form` (Key: `_formKey`)
              - `Column`
                - `TextFormField` (Controller: `_emailController`)
                - `SizedBox`
                - `TextFormField` (Controller: `_passwordController`, Obscure Text)
                - `SizedBox`
                - `GradientButton` (onPressed: `_authController.login`)
                - `SizedBox`
                - `TextButton` ("Belum punya akun? Daftar")

---

## 2. Register View (`register_screen.dart`)
- `Scaffold`
  - `SafeArea`
    - `SingleChildScrollView`
      - `Container`
        - `Padding`
          - `Column`
            - `Row` (Logo & Title)
            - `Text` ("Buat Akun Baru")
            - `Form` (Key: `_formKey`)
              - `Column`
                - `TextFormField` (Full Name)
                - `TextFormField` (Email)
                - `TextFormField` (Password)
                - `TextFormField` (NIP/NIS)
                - `DropdownButtonFormField` (Pilih Peran: Siswa/Guru)
                - `DropdownButtonFormField` (Pilih Kelas - khusus Siswa)
                - `GradientButton` (onPressed: `_authController.register`)
                - `TextButton` ("Sudah punya akun? Masuk")

---

## 3. Update Password View (`update_password_screen.dart`)
- `Scaffold`
  - `AppBar` ("Perbarui Kata Sandi")
  - `Padding`
    - `Column`
      - `Form`
        - `TextFormField` (New Password)
        - `TextFormField` (Confirm Password)
        - `GradientButton` (onPressed: `_authController.updatePassword`)
