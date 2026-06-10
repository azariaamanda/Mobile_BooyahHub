-- =============================================================
-- LANGKAH 1: Cek apakah akun owner sudah ada
-- =============================================================
SELECT id_akun, email, role, status_akun
FROM akun
WHERE role = 'owner';

-- =============================================================
-- LANGKAH 2: Cek apakah pgcrypto tersedia (untuk SHA256)
-- =============================================================
SELECT encode(digest('owner123', 'sha256'), 'hex') AS hash_test;

-- =============================================================
-- LANGKAH 3: Insert ke tabel akun
-- Jalankan ini SETELAH memastikan Langkah 2 berhasil
-- =============================================================
INSERT INTO akun (email, kata_sandi, role, status_akun)
VALUES (
  'owner@booyahhub.com',
  encode(digest('owner123', 'sha256'), 'hex'),
  'owner',
  'aktif'
)
ON CONFLICT (email) DO UPDATE
  SET kata_sandi = encode(digest('owner123', 'sha256'), 'hex'),
      status_akun = 'aktif';

-- =============================================================
-- LANGKAH 4: Insert ke profil_owner
-- =============================================================
INSERT INTO profil_owner (akun_id, nama_lengkap, no_handphone)
SELECT id_akun, 'Owner BooyahHub', '08123456789'
FROM akun
WHERE email = 'owner@booyahhub.com'
ON CONFLICT (akun_id) DO NOTHING;

-- =============================================================
-- LANGKAH 5: Verifikasi — harus muncul 1 baris
-- =============================================================
SELECT a.id_akun, a.email, a.role, a.status_akun, p.nama_lengkap
FROM akun a
JOIN profil_owner p ON p.akun_id = a.id_akun
WHERE a.email = 'owner@booyahhub.com';
