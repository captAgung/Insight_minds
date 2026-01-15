# 🔐 Cara Clear Credential Windows untuk captAgung

## ❌ Masalah

Git masih menggunakan credential RIVALDY251 meskipun sudah setup untuk captAgung:
```
remote: Permission to captAgung/Insight_minds.git denied to RIVALDY251.
```

## ✅ Solusi: Clear Credential di Windows

### **Metode 1: Menggunakan Windows Credential Manager (GUI)**

1. **Buka Windows Credential Manager:**
   - Tekan `Windows + R`
   - Ketik: `control /name Microsoft.CredentialManager`
   - Atau: Control Panel → Credential Manager → Windows Credentials

2. **Cari Credential GitHub:**
   - Scroll ke bagian **"Generic Credentials"**
   - Cari entry yang berisi:
     - `git:https://github.com`
     - Atau `github.com`
     - Atau yang berisi username `RIVALDY251`

3. **Hapus Credential:**
   - Klik credential yang salah
   - Klik **"Remove"** atau **"Delete"**
   - Konfirmasi penghapusan

4. **Verifikasi:**
   - Pastikan tidak ada credential GitHub yang tersimpan
   - Atau hanya ada credential untuk captAgung

### **Metode 2: Menggunakan Command Line**

```powershell
# List semua credential GitHub
cmdkey /list | Select-String -Pattern "github"

# Hapus credential GitHub (ganti dengan nama yang muncul di list)
cmdkey /delete:git:https://github.com

# Atau hapus semua credential GitHub
cmdkey /list | ForEach-Object {
    if ($_ -match "github") {
        $name = ($_ -split ":")[1].Trim()
        cmdkey /delete:$name
    }
}
```

### **Metode 3: Menggunakan Git Credential Helper**

```bash
# Clear credential untuk GitHub
git credential reject <<EOF
protocol=https
host=github.com
EOF

# Atau
echo "protocol=https
host=github.com" | git credential reject
```

### **Metode 4: Hapus File Credential (Manual)**

1. Buka folder:
   ```
   C:\Users\YourName\AppData\Local\GitCredentialManager\
   ```

2. Hapus file yang berisi credential GitHub

---

## 🎯 Langkah Lengkap Setelah Clear Credential

### **1. Clear Credential**

Pilih salah satu metode di atas untuk clear credential.

### **2. Setup Git Config**

```bash
cd C:\path\to\Insight_minds

# Setup untuk captAgung
git config --local user.name "captAgung"
git config --local user.email "githubblastid@gmail.com"

# Verifikasi
git config --local user.name
git config --local user.email
```

### **3. Pastikan Remote Benar**

```bash
# Cek remote
git remote -v

# Pastikan origin mengarah ke captAgung
git remote set-url origin https://github.com/captAgung/Insight_minds.git

# Verifikasi
git remote -v
```

### **4. Buat Personal Access Token**

1. Login ke GitHub dengan akun **captAgung**
2. Buka: https://github.com/settings/tokens
3. Klik **"Generate new token"** → **"Generate new token (classic)"**
4. **Note:** `InsightMind Project`
5. **Expiration:** 90 days (atau sesuai kebutuhan)
6. **Select scopes:** Centang `repo` (full control)
7. Klik **"Generate token"**
8. **Copy token** (contoh: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
9. **Simpan token** di tempat aman!

### **5. Push dengan Token**

```bash
# Coba push
git push origin main
```

Saat diminta credential:
- **Username:** `captAgung`
- **Password:** `[Paste Personal Access Token di sini]`

**Jangan gunakan password GitHub biasa!** Gunakan Personal Access Token.

### **6. Simpan Credential (Opsional)**

Setelah push berhasil, credential akan tersimpan otomatis untuk penggunaan selanjutnya.

---

## ✅ Verifikasi Setelah Setup

```bash
# 1. Cek config
git config --local user.name    # Harus: captAgung
git config --local user.email   # Harus: githubblastid@gmail.com

# 2. Cek remote
git remote -v
# Origin harus: https://github.com/captAgung/Insight_minds.git

# 3. Cek credential (tidak ada credential RIVALDY251)
cmdkey /list | Select-String -Pattern "github"

# 4. Test push
git push origin main
# Harus berhasil tanpa error 403
```

---

## 🔑 Tips

1. **Gunakan Personal Access Token** - Lebih aman daripada password
2. **Simpan token dengan aman** - Token hanya muncul sekali
3. **Set expiration** - Buat token dengan expiration yang wajar
4. **Gunakan token per project** - Buat token khusus untuk InsightMind

---

## ⚠️ Jika Masih Error

Jika masih error setelah clear credential:

1. **Restart komputer** - Untuk memastikan credential benar-benar ter-clear
2. **Cek apakah login di browser** - Pastikan browser juga login dengan akun captAgung
3. **Gunakan SSH** - Alternatif yang lebih aman:
   ```bash
   # Generate SSH key
   ssh-keygen -t ed25519 -C "githubblastid@gmail.com"
   
   # Tambah SSH key ke GitHub
   # Copy isi: ~/.ssh/id_ed25519.pub
   # Paste di: GitHub Settings > SSH and GPG keys
   
   # Ubah remote ke SSH
   git remote set-url origin git@github.com:captAgung/Insight_minds.git
   ```

---

**Setelah clear credential dan setup ulang, push akan berhasil!** ✅
