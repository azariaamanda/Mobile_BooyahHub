-- =============================================================
-- Update limit_utang admin: 50.000 → 100.000
-- Jalankan di: Supabase → SQL Editor → New Query → Run
-- =============================================================

-- 1. Update semua admin yang masih pakai nilai lama (50.000)
UPDATE profil_admin
SET    limit_utang = 100000
WHERE  limit_utang = 50000;

-- 2. Ubah default kolom agar admin baru otomatis dapat 100.000
ALTER TABLE profil_admin
  ALTER COLUMN limit_utang SET DEFAULT 100000;

-- Verifikasi
SELECT akun_id, limit_utang
FROM   profil_admin
ORDER  BY akun_id;
