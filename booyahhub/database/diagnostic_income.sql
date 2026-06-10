-- =============================================================
-- DIAGNOSTIC: Cek kenapa pendapatan = 0
-- Jalankan di Supabase → SQL Editor → New Query → Run
-- Jalankan SETELAH admin konfirmasi pembayaran minimal 1 tim
-- =============================================================

-- ── A. Cek apakah trigger ada ──────────────────────────────────
SELECT trigger_name, event_manipulation, action_timing
FROM   information_schema.triggers
WHERE  trigger_name = 'trg_auto_keuangan_scrim';
-- Jika kosong → trigger TIDAK ADA → jalankan supabase_functions.sql

-- ── B. Cek tabel yang dibutuhkan trigger ───────────────────────
SELECT
  EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'keuangan_scrim')       AS ada_keuangan_scrim,
  EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'transaksi_fee_admin')  AS ada_transaksi_fee_admin;
-- Jika FALSE → jalankan create_missing_tables.sql DULU, baru supabase_functions.sql

-- ── C. Cek apakah ada pendaftaran yang dikonfirmasi ────────────
SELECT status_pembayaran, COUNT(*) AS jumlah
FROM   pendaftaran_tim
GROUP  BY status_pembayaran;
-- Jika TIDAK ADA baris 'dikonfirmasi' → konfirmasi di DB gagal (rollback)

-- ── D. Cek pengaturan_fee ──────────────────────────────────────
SELECT fee_platform_persen, fee_admin_persen, is_persentase_admin,
       fee_admin_tetap, nominal_minimum_platform
FROM   pengaturan_fee;
-- Pastikan fee_admin_persen > 0 dan fee_platform_persen > 0

-- ── E. Cek isi keuangan_scrim (jika tabel ada) ─────────────────
-- SELECT * FROM keuangan_scrim LIMIT 10;
-- Jika kosong → trigger belum pernah berhasil

-- ── F. Cek transaksi_fee_admin (jika tabel ada) ────────────────
-- SELECT * FROM transaksi_fee_admin LIMIT 10;
