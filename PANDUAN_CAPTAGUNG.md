# 🚀 Panduan Git Collaboration untuk captAgung

## 👤 Informasi GitHub
- **Username GitHub:** captAgung
- **Email:** githubblastid@gmail.com
- **Repository Teman:** https://github.com/Favianyumna/Insight_minds.git

---

## 📋 Langkah 1: Setup Git (Sekali Saja)

### **1.1 Install Git (jika belum)**
Download dari: https://git-scm.com/download/win

### **1.2 Konfigurasi Git dengan Nama dan Email Anda**

Buka PowerShell atau Terminal, lalu jalankan:

```bash
git config --global user.name "captAgung"
git config --global user.email "githubblastid@gmail.com"
```

### **1.3 Verifikasi Konfigurasi**

```bash
git config --global user.name
git config --global user.email
```

**Output yang diharapkan:**
```
captAgung
githubblastid@gmail.com
```

---

## 📋 Langkah 2: Fork Repository Teman

### **2.1 Login ke GitHub**

1. Buka https://github.com
2. Login dengan akun **captAgung**
3. Pastikan email yang terdaftar: `githubblastid@gmail.com`

### **2.2 Fork Repository**

1. Buka repository teman:
   ```
   https://github.com/Favianyumna/Insight_minds
   ```

2. Klik tombol **"Fork"** (di pojok kanan atas)
3. Tunggu sampai fork selesai

**Setelah fork, Anda akan punya repository sendiri:**
```
https://github.com/captAgung/Insight_minds
```

---

## 📋 Langkah 3: Clone Fork ke Komputer

### **3.1 Buka Terminal/PowerShell**

Buka PowerShell atau Terminal di komputer Anda.

### **3.2 Clone Repository Fork Anda**

```bash
# Pindah ke folder yang diinginkan (misal: Documents)
cd C:\Users\YourName\Documents

# Clone repository fork Anda
git clone https://github.com/captAgung/Insight_minds.git

# Masuk ke folder
cd Insight_minds
```

### **3.3 Verifikasi Clone Berhasil**

```bash
# Cek apakah folder ada
dir

# Atau
ls
```

Anda akan melihat folder `flutter_insightmind_finals` (jika sudah ada dari teman).

---

## 📋 Langkah 4: Setup Remote (Sekali Saja)

### **4.1 Cek Remote yang Ada**

```bash
git remote -v
```

**Output yang diharapkan:**
```
origin    https://github.com/captAgung/Insight_minds.git (fetch)
origin    https://github.com/captAgung/Insight_minds.git (push)
```

### **4.2 Tambahkan Remote ke Repository Teman (Upstream)**

```bash
git remote add upstream https://github.com/Favianyumna/Insight_minds.git
```

### **4.3 Verifikasi Remote**

```bash
git remote -v
```

**Output yang diharapkan:**
```
origin    https://github.com/captAgung/Insight_minds.git (fetch)
origin    https://github.com/captAgung/Insight_minds.git (push)
upstream  https://github.com/Favianyumna/Insight_minds.git (fetch)
upstream  https://github.com/Favianyumna/Insight_minds.git (push)
```

---

## 📋 Langkah 5: Copy File Project (Jika Punya Project Lokal)

### **5.1 Copy File dari Project Anda**

**Opsi A: Menggunakan PowerShell**

```powershell
# Masih di folder Insight_minds
# Copy semua file dari project Anda (ganti path sesuai lokasi project Anda)
Copy-Item -Path "C:\path\to\your\project\*" -Destination "flutter_insightmind_finals\" -Recurse -Force -Exclude ".git"
```

**Opsi B: Manual Copy**

1. Buka folder project Anda
2. Select All (Ctrl+A)
3. Copy (Ctrl+C)
4. Buka folder `Insight_minds/flutter_insightmind_finals`
5. Paste (Ctrl+V)
6. Replace jika diminta

### **5.2 Verifikasi File Ter-Copy**

```bash
git status
```

Anda akan melihat banyak file "Untracked files" - ini normal.

---

## 📋 Langkah 6: Commit & Push

### **6.1 Tambahkan Semua File**

```bash
# Masih di folder Insight_minds
git add .
```

### **6.2 Commit dengan Pesan yang Jelas**

```bash
git commit -m "feat: tambah fitur [nama fitur] dengan [deskripsi singkat]"
```

**Contoh pesan commit yang baik:**
```bash
git commit -m "feat: tambah fitur psikologi dengan AI Chatbot dan Wellness Challenges"
git commit -m "fix: perbaiki error mood scan camera"
git commit -m "refactor: extract shared widgets untuk auth"
```

**Format pesan commit:**
- `feat:` untuk fitur baru
- `fix:` untuk perbaikan bug
- `refactor:` untuk refactoring code
- `docs:` untuk dokumentasi

### **6.3 Push ke GitHub**

```bash
git push origin main
```

**Jika pertama kali push:**
```bash
git push -u origin main
```

### **6.4 Verifikasi di GitHub**

1. Buka repository fork Anda di browser:
   ```
   https://github.com/captAgung/Insight_minds
   ```
2. Klik tab **"Commits"**
3. Commit Anda akan muncul di sini ✅

---

## 📋 Langkah 7: Buat Pull Request

### **7.1 Buka Repository Fork Anda**

Buka di browser:
```
https://github.com/captAgung/Insight_minds
```

### **7.2 Klik "Contribute"**

1. Klik tombol **"Contribute"** (hijau, di bagian atas)
2. Klik **"Open Pull Request"**

### **7.3 Isi Deskripsi Pull Request**

**Judul:**
```
feat: Tambah fitur [nama fitur]
```

**Deskripsi:**
```markdown
## Deskripsi
Menambahkan fitur [nama fitur] dengan [deskripsi].

## Perubahan
- ✅ Tambah fitur [fitur 1]
- ✅ Tambah fitur [fitur 2]
- ✅ Perbaikan [perbaikan]

## Testing
- [x] Fitur berfungsi dengan baik
- [x] Tidak ada error
- [x] Mengikuti coding standards

## Checklist
- [x] Code sudah di-test
- [x] Tidak ada error
- [x] Mengikuti coding standards
```

### **7.4 Mention Teman**

Di deskripsi atau komentar, mention teman:
```markdown
Hi @Favianyumna, 
Mohon di-review dan di-merge jika sudah oke.
Terima kasih!
```

### **7.5 Create Pull Request**

1. Klik tombol **"Create Pull Request"**
2. PR Anda akan muncul di repository teman
3. Teman akan mendapat notifikasi

---

## 📋 Langkah 8: Workflow Harian

### **8.1 Setiap Kali Mulai Kerja**

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

# 6. PR akan otomatis ter-update! ✅
```

---

## 📋 Langkah 9: Melihat Update Teman

### **9.1 Melihat di GitHub (Web)**

1. Buka: `https://github.com/Favianyumna/Insight_minds`
2. Klik tab **"Commits"** → lihat semua commit
3. Klik tab **"Pull requests"** → lihat semua PR
4. Klik tab **"Insights"** → **"Contributors"** → lihat contributor

### **9.2 Melihat di Terminal**

```bash
# Fetch update dari repository teman
git fetch upstream

# Lihat commit dari teman
git log upstream/main --oneline

# Lihat commit terbaru (10 terakhir)
git log upstream/main --oneline -10
```

---

## ✅ Checklist Lengkap untuk captAgung

### **Setup Awal:**
- [ ] Git sudah terinstall
- [ ] Git config sudah di-setup (nama: captAgung, email: githubblastid@gmail.com)
- [ ] Login ke GitHub dengan akun captAgung
- [ ] Fork repository Favianyumna/Insight_minds
- [ ] Clone fork ke komputer
- [ ] Setup remote upstream

### **Bekerja:**
- [ ] Sync dengan repository teman sebelum kerja
- [ ] Copy file project (jika perlu)
- [ ] Commit dengan pesan jelas
- [ ] Push ke fork
- [ ] Buat Pull Request
- [ ] Mention teman di PR

---

## 🎯 Quick Reference

### **Command Cheat Sheet:**

```bash
# Setup
git config --global user.name "captAgung"
git config --global user.email "githubblastid@gmail.com"
git remote add upstream https://github.com/Favianyumna/Insight_minds.git

# Update
git fetch upstream
git merge upstream/main
git push origin main

# Commit
git add .
git commit -m "feat: deskripsi"
git push origin main

# Lihat History
git log --oneline
git log upstream/main --oneline
```

---

## 🎉 Selesai!

Setelah mengikuti panduan ini, captAgung bisa:
- ✅ Fork repository teman
- ✅ Clone dan setup repository lokal
- ✅ Commit dan push perubahan
- ✅ Buat Pull Request
- ✅ Melihat update dari teman
- ✅ Bekerja bersama tanpa kehilangan progress

**Selamat berkolaborasi! 🚀**

---

**Dibuat untuk:** captAgung (githubblastid@gmail.com)  
**Repository:** https://github.com/Favianyumna/Insight_minds  
**Update terakhir:** 2026-01-14
