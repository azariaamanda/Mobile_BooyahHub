-- ============================================================
-- RESET SEMUA DATA PEMBAYARAN — clean slate
-- Supabase → SQL Editor → New Query → paste → Run
-- PERINGATAN: Data yang dihapus TIDAK BISA dikembalikan!
-- ============================================================

BEGIN;

-- 1. Hapus klaim hadiah dulu (FK ke pendaftaran_tim)
DELETE FROM klaim_hadiah;

-- 2. Hapus semua pendaftaran tim
DELETE FROM pendaftaran_tim;

-- 3. Hapus riwayat pelunasan utang admin
DELETE FROM pelunasan_utang_admin;

COMMIT;

-- Verifikasi — semua harus menampilkan 0
SELECT 'pendaftaran_tim'      AS tabel, COUNT(*) AS sisa FROM pendaftaran_tim
UNION ALL
SELECT 'klaim_hadiah',                  COUNT(*)         FROM klaim_hadiah
UNION ALL
SELECT 'pelunasan_utang_admin',         COUNT(*)         FROM pelunasan_utang_admin;
