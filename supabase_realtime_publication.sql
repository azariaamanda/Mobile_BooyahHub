-- Enable Supabase Realtime for owner-side tables.
-- Jalankan script ini SEKALI di Supabase Dashboard → SQL Editor.
-- Tanpa ini, subscribe realtime dari Flutter app tidak akan menerima event.

ALTER PUBLICATION supabase_realtime ADD TABLE profil_admin;
ALTER PUBLICATION supabase_realtime ADD TABLE profil_owner;
ALTER PUBLICATION supabase_realtime ADD TABLE scrim;
ALTER PUBLICATION supabase_realtime ADD TABLE sesi_scrim;
ALTER PUBLICATION supabase_realtime ADD TABLE pendaftaran_tim;
ALTER PUBLICATION supabase_realtime ADD TABLE pelunasan_utang_admin;
ALTER PUBLICATION supabase_realtime ADD TABLE transaksi_premium;
ALTER PUBLICATION supabase_realtime ADD TABLE pengaturan_fee;

-- Tabel `akun` TIDAK di-publish (info sensitif).
-- Perubahan status akun cukup di-handle lewat tabel `notifikasi`.

-- Verifikasi setelah run:
--   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
-- Pastikan 8 tabel di atas muncul (atau yang sudah ada sebelumnya, mis. `notifikasi`).
