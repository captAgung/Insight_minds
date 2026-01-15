# 🔐 Cara Fix Credential untuk captAgung

## ❌ Masalah

Error 403 saat push meskipun sudah login dengan akun captAgung:
```
remote: Permission to captAgung/Insight_minds.git denied to RIVALDY251.
fatal: unable to access 'https://github.com/captAgung/Insight_minds.git/': 
The requested URL returned error: 403
```

## 🔍 Penyebab

Git masih menggunakan credential cache dari akun RIVALDY251, bukan captAgung.

## ✅ Solusi

### **1. Setup Git Config untuk captAgung**

```bash
# Masuk ke folder repository
cd C:\path\to\Insight_minds

# Setup Git config lokal (untuk repository ini saja)
git config --local user.name "captAgung"
git config --local user.email "githubblastid@gmail.com"

# Verifikasi
git config --local user.name
git config --local user.email
```

### **2. Pastikan Remote Origin Benar**

```bash
# Cek remote
git remote -v

# Jika origin salah, perbaiki:
git remote set-url origin https://github.com/captAgung/Insight_minds.git

# Verifikasi
git remote -v
```

**Output yang benar:**
```
origin    https://github.com/captAgung/Insight_minds.git (fetch)
origin    https://github.com/captAgung/Insight_minds.git (push)
upstream  https://github.com/Favianyumna/Insight_minds.git (fetch)
upstream  https://github.com/Favianyumna/Insight_minds.git (push)
```

### **3. Clear Credential Cache**

**Opsi A: Menggunakan Git Credential Manager**

```bash
# Clear credential untuk GitHub
git credential-manager-core erase

# Atau
git credential reject https://github.com
```

**Opsi B: Manual Clear di Windows Credential Manager**

1. Buka **Control Panel**
2. Pilih **Credential Manager**
3. Pilih **Windows Credentials**
4. Cari credential yang berisi `github.com` atau `git:https://github.com`
5. Klik **Remove** untuk credential yang salah (RIVALDY251)
6. Atau **Edit** dan ganti dengan credential captAgung

**Opsi C: Clear Semua Credential GitHub**

```bash
# Hapus semua credential GitHub
cmdkey /list | findstr github
cmdkey /delete:git:https://github.com
```

### **4. Login Ulang dengan Akun captAgung**

Setelah clear credential, saat push pertama kali:

```bash
git push origin main
```

Git akan meminta credential:
- **Username:** captAgung
- **Password:** Gunakan Personal Access Token (bukan password GitHub)

**Cara buat Personal Access Token:**
1. Buka: https://github.com/settings/tokens
2. Klik **"Generate new token"** → **"Generate new token (classic)"**
3. Beri nama: `InsightMind Project`
4. Pilih scope: `repo` (full control of private repositories)
5. Klik **"Generate token"**
6. Copy token (hanya muncul sekali!)
7. Gunakan token sebagai password saat Git meminta credential

### **5. Simpan Credential (Opsional)**

Setelah login berhasil, credential akan tersimpan otomatis.

---

## 🎯 Langkah Lengkap

```bash
# 1. Masuk ke folder repository
cd C:\Users\YourName\Documents\Insight_minds

# 2. Setup Git config
git config --local user.name "captAgung"
git config --local user.email "githubblastid@gmail.com"

# 3. Pastikan remote benar
git remote set-url origin https://github.com/captAgung/Insight_minds.git

# 4. Clear credential cache
git credential reject https://github.com

# 5. Coba push (akan meminta credential baru)
git push origin main
# Masukkan username: captAgung
# Masukkan password: Personal Access Token
```

---

## 🔑 Membuat Personal Access Token

1. Login ke GitHub dengan akun **captAgung**
2. Buka: https://github.com/settings/tokens
3. Klik **"Generate new token"** → **"Generate new token (classic)"**
4. **Note:** `InsightMind Project`
5. **Expiration:** Pilih durasi (90 days atau custom)
6. **Select scopes:** Centang `repo` (full control)
7. Klik **"Generate token"**
8. **Copy token** (contoh: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
9. **Simpan token** di tempat aman (tidak akan muncul lagi!)

**Gunakan token sebagai password saat Git meminta credential.**

---

## ✅ Verifikasi

Setelah setup, verifikasi:

```bash
# Cek config
git config --local user.name    # Harus: captAgung
git config --local user.email   # Harus: githubblastid@gmail.com

# Cek remote
git remote -v
# Origin harus: https://github.com/captAgung/Insight_minds.git

# Test push
git push origin main
# Harus berhasil tanpa error 403
```

---

## ⚠️ Catatan Penting

- **Jangan gunakan password GitHub** - Gunakan Personal Access Token
- **Token hanya muncul sekali** - Simpan di tempat aman
- **Setiap orang punya repository fork sendiri** - captAgung push ke captAgung/Insight_minds
- **Credential disimpan lokal** - Tidak akan konflik dengan akun lain di komputer yang sama

---

**Setelah setup ini, push akan berhasil!** ✅
