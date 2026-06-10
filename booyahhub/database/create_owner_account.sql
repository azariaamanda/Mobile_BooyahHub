-- =============================================================
-- BUAT AKUN OWNER — 3 langkah, jalankan berurutan
-- Supabase → SQL Editor → New Query → paste semua → Run
-- Email    : owner@booyahhub.com
-- Password : owner123
-- =============================================================
-- NOTE: akun & profil_owner UNRESTRICTED → tidak perlu auth.users
-- =============================================================


-- LANGKAH 1: Aktifkan pgcrypto (untuk SHA256 hash password)
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- LANGKAH 2: Insert akun owner
INSERT INTO akun (email, kata_sandi, role, status_akun, is_premium)
VALUES (
  'owner@booyahhub.com',
  encode(digest('owner123', 'sha256'), 'hex'),
  'owner',
  'aktif',
  true
)
ON CONFLICT (email) DO UPDATE
  SET kata_sandi  = encode(digest('owner123', 'sha256'), 'hex'),
      role        = 'owner',
      status_akun = 'aktif';


-- LANGKAH 3: Insert profil owner
INSERT INTO profil_owner (akun_id, nama_lengkap, no_handphone)
SELECT id_akun, 'Owner BooyahHub', '08123456789'
FROM akun
WHERE email = 'owner@booyahhub.com'
ON CONFLICT (akun_id) DO NOTHING;


-- VERIFIKASI — harus muncul 1 baris
SELECT
  a.id_akun,
  a.email,
  a.role,
  a.status_akun,
  p.nama_lengkap
FROM akun a
JOIN profil_owner p ON p.akun_id = a.id_akun
WHERE a.email = 'owner@booyahhub.com';
