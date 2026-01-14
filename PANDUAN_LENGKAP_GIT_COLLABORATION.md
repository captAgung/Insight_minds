# 📚 Panduan Lengkap Git Collaboration - InsightMind Project

## 🎯 Tujuan
Panduan lengkap dari awal sampai akhir untuk berkolaborasi dengan teman kelompok menggunakan GitHub, tanpa perlu akses collaborator.

---

## 📋 Daftar Isi

1. [Persiapan Awal](#1-persiapan-awal)
2. [Fork Repository Teman](#2-fork-repository-teman)
3. [Clone Fork ke Komputer](#3-clone-fork-ke-komputer)
4. [Copy File Project](#4-copy-file-project)
5. [Commit & Push](#5-commit--push)
6. [Buat Pull Request](#6-buat-pull-request)
7. [Workflow Harian](#7-workflow-harian)
8. [Melihat Update Teman](#8-melihat-update-teman)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Persiapan Awal

### **1.1 Dapatkan Link Repository Teman**

Minta teman kelompok untuk memberikan:
- **Link repository GitHub** (contoh: `https://github.com/username/repo-name.git`)
- **Username GitHub teman** (untuk mention di PR)

**Contoh:**
- Repository: `https://github.com/Favianyumna/Insight_minds.git`
- Username: `Favianyumna`

### **1.2 Pastikan Git Terinstall**

Buka PowerShell/Terminal dan cek:

```bash
git --version
```

Jika belum terinstall, download dari: https://git-scm.com/downloads

### **1.3 Setup Git Config (sekali saja)**

```bash
git config --global user.name "Nama Anda"
git config --global user.email "email@example.com"
```

**Contoh:**
```bash
git config --global user.name "RIVALDY251"
git config --global user.email "rival.ganten99@gmail.com"
```

---

## 2. Fork Repository Teman

### **2.1 Login ke GitHub**

1. Buka browser
2. Login ke GitHub dengan akun Anda
3. Pastikan sudah login dengan benar

### **2.2 Fork Repository**

1. Buka link repository teman di browser:
   ```
   https://github.com/Favianyumna/Insight_minds
   ```
2. Klik tombol **"Fork"** di pojok kanan atas
3. Tunggu sampai proses fork selesai
4. Anda akan diarahkan ke repository fork Anda

**URL Repository Fork Anda:**
```
https://github.com/YOUR-USERNAME/Insight_minds
```

**Contoh:**
```
https://github.com/RIVALDY251/Insight_minds
```

---

## 3. Clone Fork ke Komputer

### **3.1 Buka Terminal/PowerShell**

Buka PowerShell atau Terminal di komputer Anda.

### **3.2 Clone Repository**

```bash
# Pindah ke folder yang diinginkan (misal: Documents)
cd C:\Users\YourName\Documents

# Clone repository fork Anda (ganti YOUR-USERNAME dengan username GitHub Anda)
git clone https://github.com/YOUR-USERNAME/Insight_minds.git

# Masuk ke folder
cd Insight_minds
```

**Contoh:**
```bash
cd C:\Users\YourName\Documents
git clone https://github.com/RIVALDY251/Insight_minds.git
cd Insight_minds
```

### **3.3 Verifikasi Clone Berhasil**

```bash
# Cek apakah folder ada
ls

# Atau di Windows
dir
```

Anda akan melihat folder `flutter_insightmind_finals` (jika sudah ada dari teman).

---

## 4. Copy File Project

### **4.1 Copy File dari Project Anda**

**Opsi A: Menggunakan PowerShell (Recommended)**

```powershell
# Masih di folder Insight_minds
# Copy semua file dari project Anda (ganti path sesuai lokasi project Anda)
Copy-Item -Path "C:\flutter_insightmind_finals\*" -Destination "." -Recurse -Force -Exclude ".git"
```

**Opsi B: Manual Copy**

1. Buka folder project Anda: `C:\flutter_insightmind_finals`
2. Select All (Ctrl+A)
3. Copy (Ctrl+C)
4. Buka folder `Insight_minds` (yang sudah di-clone)
5. Paste (Ctrl+V)
6. Replace jika diminta

### **4.2 Verifikasi File Ter-Copy**

```bash
# Cek apakah file sudah ter-copy
git status
```

Anda akan melihat banyak file "Untracked files" - ini normal.

---

## 5. Commit & Push

### **5.1 Tambahkan Semua File**

```bash
# Masih di folder Insight_minds
git add .
```

### **5.2 Commit dengan Pesan yang Jelas**

```bash
git commit -m "feat: tambah fitur [nama fitur] dengan [deskripsi singkat]"
```

**Contoh pesan commit yang baik:**
```bash
git commit -m "feat: tambah fitur auth (login, register, profile) dengan UI profesional"
git commit -m "fix: perbaiki error Hive box users"
git commit -m "refactor: extract shared widgets untuk auth"
git commit -m "docs: tambah dokumentasi API"
```

**Format pesan commit:**
- `feat:` untuk fitur baru
- `fix:` untuk perbaikan bug
- `refactor:` untuk refactoring code
- `docs:` untuk dokumentasi
- `style:` untuk formatting
- `test:` untuk test

### **5.3 Push ke GitHub**

```bash
git push origin main
```

**Jika pertama kali push:**
```bash
git push -u origin main
```

### **5.4 Verifikasi di GitHub**

1. Buka repository fork Anda di browser:
   ```
   https://github.com/YOUR-USERNAME/Insight_minds
   ```
2. Klik tab **"Commits"**
3. Commit Anda akan muncul di sini ✅

---

## 6. Buat Pull Request

### **6.1 Buka Repository Fork Anda**

Buka di browser:
```
https://github.com/YOUR-USERNAME/Insight_minds
```

### **6.2 Klik "Contribute"**

1. Klik tombol **"Contribute"** (hijau, di bagian atas)
2. Klik **"Open Pull Request"**

### **6.3 Isi Deskripsi Pull Request**

**Judul:**
```
feat: Tambah fitur [nama fitur]
```

**Deskripsi:**
```markdown
## Deskripsi
Menambahkan fitur [nama fitur] dengan [deskripsi].

## Perubahan
- ✅ Tambah fitur login dengan UI profesional
- ✅ Tambah fitur register dengan validasi lengkap
- ✅ Tambah halaman profile dengan logout
- ✅ Refactoring struktur dengan shared components

## Testing
- [x] Login berhasil
- [x] Register berhasil
- [x] Logout berhasil

## Screenshot (opsional)
[Upload screenshot jika ada]

## Checklist
- [x] Code sudah di-test
- [x] Tidak ada error
- [x] Mengikuti coding standards
```

### **6.4 Mention Teman**

Di deskripsi atau komentar, mention teman:
```markdown
Hi @Favianyumna, 
Mohon di-review dan di-merge jika sudah oke.
Terima kasih!
```

### **6.5 Create Pull Request**

1. Klik tombol **"Create Pull Request"**
2. PR Anda akan muncul di repository teman
3. Teman akan mendapat notifikasi

---

## 7. Workflow Harian

### **7.1 Setup Upstream (sekali saja)**

```bash
# Masuk ke folder repository fork Anda
cd C:\Users\YourName\Documents\Insight_minds

# Tambahkan remote repository teman sebagai upstream
git remote add upstream https://github.com/Favianyumna/Insight_minds.git

# Verifikasi
git remote -v
```

**Output yang diharapkan:**
```
origin    https://github.com/YOUR-USERNAME/Insight_minds.git (fetch)
origin    https://github.com/YOUR-USERNAME/Insight_minds.git (push)
upstream  https://github.com/Favianyumna/Insight_minds.git (fetch)
upstream  https://github.com/Favianyumna/Insight_minds.git (push)
```

### **7.2 Workflow Setiap Kali Mulai Kerja**

```bash
# 1. Masuk ke folder repository
cd C:\Users\YourName\Documents\Insight_minds

# 2. Sync dengan repository teman (PENTING!)
git fetch upstream
git merge upstream/main

# 3. Buat perubahan
# ... edit code di editor ...

# 4. Commit perubahan
git add .
git commit -m "feat: deskripsi perubahan"

# 5. Push ke fork Anda
git push origin main

# 6. Buat Pull Request baru (jika perlu)
# Atau update PR yang sudah ada
```

---

## 8. Melihat Update Teman

### **8.1 Melihat di GitHub (Web)**

#### **A. Di Repository Teman:**

1. Buka: `https://github.com/Favianyumna/Insight_minds`
2. Klik tab **"Commits"** → lihat semua commit
3. Klik tab **"Pull requests"** → lihat semua PR
4. Klik tab **"Insights"** → **"Contributors"** → lihat contributor
5. Klik tab **"Insights"** → **"Network"** → lihat graph commit

#### **B. Di Repository Fork Anda:**

1. Buka: `https://github.com/YOUR-USERNAME/Insight_minds`
2. Klik tab **"Commits"** → lihat commit Anda
3. Klik tab **"Pull requests"** → lihat PR yang sudah dibuat

### **8.2 Melihat di Terminal**

```bash
# Masuk ke folder repository
cd C:\Users\YourName\Documents\Insight_minds

# Fetch update dari repository teman
git fetch upstream

# Lihat commit dari teman
git log upstream/main --oneline

# Lihat commit terbaru (10 terakhir)
git log upstream/main --oneline -10

# Lihat detail commit tertentu
git show upstream/main

# Lihat file yang berbeda
git diff main upstream/main --name-only

# Lihat detail perbedaan
git diff main upstream/main
```

### **8.3 Sync dengan Repository Teman**

```bash
# Pull perubahan dari teman
git fetch upstream
git merge upstream/main

# Atau dengan rebase (lebih rapi)
git fetch upstream
git rebase upstream/main

# Push setelah sync
git push origin main
```

---

## 9. Troubleshooting

### **9.1 Error: "Permission denied"**

**Masalah:** Tidak bisa push ke repository teman langsung.

**Solusi:** 
- Gunakan Fork (sudah dijelaskan di langkah 2)
- Atau minta teman untuk menambahkan Anda sebagai collaborator

### **9.2 Error: "Repository not found"**

**Masalah:** Repository tidak ditemukan.

**Solusi:**
- Pastikan URL repository benar
- Pastikan repository adalah public (atau Anda punya akses)
- Pastikan sudah login ke GitHub

### **9.3 Error: "Failed to push some refs"**

**Masalah:** Push ditolak karena ada perubahan di remote.

**Solusi:**
```bash
# Pull dulu sebelum push
git pull origin main --rebase

# Atau
git fetch origin
git merge origin/main

# Lalu push lagi
git push origin main
```

### **9.4 Error: "Your branch is behind"**

**Masalah:** Branch lokal ketinggalan dari remote.

**Solusi:**
```bash
# Pull perubahan terbaru
git pull origin main

# Atau
git fetch origin
git merge origin/main
```

### **9.5 Conflict saat Merge**

**Masalah:** Ada conflict saat merge dengan repository teman.

**Solusi:**
```bash
# 1. Lihat file yang conflict
git status

# 2. Buka file yang conflict di editor
# Cari tanda:
# <<<<<<< HEAD
# kode Anda
# =======
# kode teman
# >>>>>>> upstream/main

# 3. Edit file, pilih kode yang benar atau gabungkan

# 4. Setelah selesai:
git add .
git commit -m "resolve: fix conflict dengan repository teman"
git push origin main
```

### **9.6 PR Belum Di-Merge**

**Masalah:** Pull Request masih "Open" dan belum di-merge.

**Solusi:**
- Mention teman di komentar PR: `@Favianyumna`
- Chat langsung ke teman untuk mengingatkan
- Pastikan deskripsi PR jelas dan lengkap

### **9.7 Commit Belum Muncul di Contributors**

**Masalah:** Commit sudah di-push tapi belum muncul di Contributors.

**Solusi:**
- Pastikan PR sudah di-merge oleh teman
- Setelah di-merge, commit akan muncul otomatis
- Refresh halaman GitHub setelah beberapa menit

---

## ✅ Checklist Lengkap

### **Setup Awal:**
- [ ] Git sudah terinstall
- [ ] Git config sudah di-setup
- [ ] Dapatkan link repository teman
- [ ] Login ke GitHub

### **Fork & Clone:**
- [ ] Fork repository teman
- [ ] Clone fork ke komputer
- [ ] Verifikasi clone berhasil

### **Copy & Commit:**
- [ ] Copy file project ke repository fork
- [ ] Commit dengan pesan yang jelas
- [ ] Push ke GitHub
- [ ] Verifikasi commit muncul di GitHub

### **Pull Request:**
- [ ] Buat Pull Request
- [ ] Isi deskripsi yang jelas
- [ ] Mention teman di PR
- [ ] Tunggu teman review dan merge

### **Workflow Harian:**
- [ ] Setup upstream (sekali saja)
- [ ] Sync dengan repository teman sebelum kerja
- [ ] Commit perubahan dengan pesan jelas
- [ ] Push ke fork
- [ ] Buat/update Pull Request jika perlu

---

## 📝 Tips & Best Practices

### **1. Commit Message yang Baik:**
```bash
# ✅ BAIK:
git commit -m "feat: tambah halaman login dengan validasi"
git commit -m "fix: perbaiki error Hive box users"
git commit -m "refactor: extract shared widgets untuk auth"

# ❌ BURUK:
git commit -m "update"
git commit -m "fix"
git commit -m "perubahan"
```

### **2. Commit Sering dengan Pesan Jelas:**
- Jangan tunggu sampai banyak perubahan baru commit
- Commit setiap fitur/perbaikan selesai
- Pesan commit harus jelas dan deskriptif

### **3. Selalu Pull Sebelum Push:**
```bash
# SELALU lakukan ini sebelum push:
git fetch upstream
git merge upstream/main
# ... baru push
```

### **4. Komunikasi dengan Teman:**
- Informasikan fitur yang sedang dikerjakan
- Jangan edit file yang sama bersamaan
- Gunakan Pull Request untuk diskusi

### **5. Jangan Commit File yang Tidak Perlu:**
Pastikan file `.gitignore` sudah benar:
```
# Flutter/Dart
.dart_tool/
.flutter-plugins
build/
*.iml

# Environment
.env
.env.local

# Logs
*.log
```

---

## 🎯 Quick Reference

### **Command Cheat Sheet:**

```bash
# Setup
git remote add upstream <url>
git remote -v

# Update
git pull origin main
git fetch upstream
git merge upstream/main

# Commit
git status
git add .
git commit -m "pesan"
git push origin main

# Lihat History
git log --oneline
git log upstream/main --oneline
git show <commit-hash>

# Sync
git fetch upstream
git merge upstream/main
git push origin main
```

---

## 🎉 Selesai!

Setelah mengikuti panduan ini, Anda bisa:
- ✅ Fork repository teman
- ✅ Clone dan setup repository lokal
- ✅ Commit dan push perubahan Anda
- ✅ Buat Pull Request
- ✅ Melihat update dari teman
- ✅ Sync dengan repository teman
- ✅ Bekerja bersama tanpa kehilangan progress

**Selamat berkolaborasi! 🚀**

---

**Dibuat untuk:** InsightMind Project  
**Update terakhir:** 2026-01-14
