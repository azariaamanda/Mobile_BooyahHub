-- =============================================================
-- Set admin: aktif + premium + terverifikasi owner
-- Ganti 'email_admin_kamu@gmail.com' dengan email akun admin
-- Jalankan di: Supabase → SQL Editor → New Query → Run
-- =============================================================

-- 1. Aktifkan akun + set premium
UPDATE akun
SET
  status_akun = 'aktif',
  is_premium  = true
WHERE email = 'email_admin_kamu@gmail.com'
  AND role  = 'admin';

-- 2. Set verifikasi KTP = terverifikasi
UPDATE profil_admin
SET status_verifikasi_ktp = 'terverifikasi'
WHERE akun_id = (
  SELECT id_akun FROM akun
  WHERE email = 'email_admin_kamu@gmail.com'
    AND role  = 'admin'
);

-- Verifikasi hasilnya
SELECT
  a.id_akun,
  a.email,
  a.status_akun,
  a.is_premium,
  p.status_verifikasi_ktp,
  p.limit_utang
FROM akun a
JOIN profil_admin p ON p.akun_id = a.id_akun
WHERE a.email = 'email_admin_kamu@gmail.com';
