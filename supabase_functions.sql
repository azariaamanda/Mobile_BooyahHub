-- =============================================================
-- JALANKAN SELURUH FILE INI DI SUPABASE SQL EDITOR
-- Dashboard → SQL Editor → New Query → Paste → Run
-- =============================================================


-- =============================================================
-- BAGIAN 1: AUTO-HITUNG KEUANGAN + CATAT UTANG ADMIN
-- Trigger berjalan setiap kali admin mengklik "Accept/Verifikasi"
-- pembayaran → status_pembayaran berubah menjadi 'dikonfirmasi'.
--
-- Yang dilakukan otomatis:
--   ① Update keuangan_scrim (total pendapatan + fee breakdown)
--   ② Tambah total_utang admin sebesar fee per slot
--   ③ Catat di transaksi_fee_admin (riwayat tagihan)
--   ④ Cek limit → jika total_utang >= limit_utang: SUSPEND akun
-- =============================================================

CREATE OR REPLACE FUNCTION fn_auto_keuangan_scrim()
RETURNS TRIGGER AS $$
DECLARE
  v_id_scrim         INT;
  v_id_admin         INT;
  v_biaya            NUMERIC;
  v_total            NUMERIC;
  v_fee_pct_platform INT;
  v_fee_pct_admin    INT;
  v_fee_platform     NUMERIC;
  v_fee_admin        NUMERIC;
  v_sisa             NUMERIC;
  -- Untuk utang admin
  v_fee_per_slot     NUMERIC;
  v_utang_baru       NUMERIC;
  v_limit_utang      NUMERIC;
BEGIN
  -- Hanya proses saat status berubah MENJADI 'dikonfirmasi'
  IF NEW.status_pembayaran::TEXT = 'dikonfirmasi'
     AND COALESCE(OLD.status_pembayaran::TEXT, '') <> 'dikonfirmasi'
  THEN

    -- ── Ambil data scrim ──────────────────────────────────────
    SELECT ss.id_scrim, s.biaya_pendaftaran, s.id_admin
    INTO   v_id_scrim, v_biaya, v_id_admin
    FROM   sesi_scrim ss
    JOIN   scrim s ON s.id_scrim = ss.id_scrim
    WHERE  ss.id_sesi = NEW.id_sesi;

    -- ── Ambil persentase fee dari pengaturan_fee ──────────────
    SELECT fee_platform_persen, fee_admin_persen
    INTO   v_fee_pct_platform, v_fee_pct_admin
    FROM   pengaturan_fee
    WHERE  id_pengaturan = 1;

    -- ── ① UPDATE keuangan_scrim ───────────────────────────────
    -- Hitung total dari semua slot yang sudah dikonfirmasi
    SELECT COALESCE(COUNT(*), 0) * v_biaya
    INTO   v_total
    FROM   pendaftaran_tim pt
    JOIN   sesi_scrim ss ON ss.id_sesi = pt.id_sesi
    WHERE  ss.id_scrim = v_id_scrim
    AND    pt.status_pembayaran::TEXT = 'dikonfirmasi';

    v_fee_platform := ROUND(v_total * v_fee_pct_platform::NUMERIC / 100, 0);
    v_fee_admin    := ROUND(v_total * v_fee_pct_admin::NUMERIC    / 100, 0);
    v_sisa         := v_total - v_fee_platform - v_fee_admin;

    IF EXISTS (SELECT 1 FROM keuangan_scrim WHERE id_scrim = v_id_scrim) THEN
      UPDATE keuangan_scrim SET
        total_pendaftaran    = v_total,
        fee_platform_5persen = v_fee_platform,
        fee_admin_10persen   = v_fee_admin,
        sisa_hadiah          = v_sisa,
        juara1_50persen      = ROUND(v_sisa * 0.50, 0),
        juara2_30persen      = ROUND(v_sisa * 0.30, 0),
        juara3_20persen      = ROUND(v_sisa * 0.20, 0)
      WHERE id_scrim = v_id_scrim;
    ELSE
      INSERT INTO keuangan_scrim (
        id_scrim, total_pendaftaran, fee_platform_5persen,
        fee_admin_10persen, sisa_hadiah,
        juara1_50persen, juara2_30persen, juara3_20persen
      ) VALUES (
        v_id_scrim, v_total, v_fee_platform, v_fee_admin, v_sisa,
        ROUND(v_sisa * 0.50, 0),
        ROUND(v_sisa * 0.30, 0),
        ROUND(v_sisa * 0.20, 0)
      );
    END IF;

    -- ── ② TAMBAH total_utang admin (fee per 1 slot) ───────────
    v_fee_per_slot := ROUND(v_biaya * v_fee_pct_admin::NUMERIC / 100, 0);

    UPDATE profil_admin
    SET    total_utang = total_utang + v_fee_per_slot
    WHERE  akun_id = v_id_admin
    RETURNING total_utang, limit_utang
    INTO  v_utang_baru, v_limit_utang;

    -- ── ③ CATAT di transaksi_fee_admin (riwayat tagihan) ─────
    INSERT INTO transaksi_fee_admin (
      admin_id, nominal, jumlah_slot, sisa_limit_setelah
    ) VALUES (
      v_id_admin,
      v_fee_per_slot,
      1,
      v_limit_utang - v_utang_baru
    );

    -- ── ④ CEK LIMIT → SUSPEND jika sudah melewati batas ──────
    IF v_utang_baru >= v_limit_utang THEN
      UPDATE akun
      SET    status_akun = 'suspended'
      WHERE  id_akun = v_id_admin;
    END IF;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pasang trigger ke tabel pendaftaran_tim
DROP TRIGGER IF EXISTS trg_auto_keuangan_scrim ON pendaftaran_tim;
CREATE TRIGGER trg_auto_keuangan_scrim
  AFTER UPDATE ON pendaftaran_tim
  FOR EACH ROW
  EXECUTE FUNCTION fn_auto_keuangan_scrim();


-- =============================================================
-- BAGIAN 2: DISTRIBUSI HADIAH KE PEMENANG (JUARA 1/2/3)
-- Dipanggil dari Flutter saat admin tekan "Bagi Hadiah"
-- setelah sesi selesai dan semua skor diinput.
-- =============================================================

CREATE OR REPLACE FUNCTION fn_bagi_hadiah(p_id_sesi INT)
RETURNS JSONB AS $$
DECLARE
  v_id_scrim  INT;
  v_juara1    NUMERIC := 0;
  v_juara2    NUMERIC := 0;
  v_juara3    NUMERIC := 0;
  v_rank      INT     := 1;
  v_hadiah    NUMERIC;
  rec         RECORD;
BEGIN

  SELECT id_scrim INTO v_id_scrim
  FROM   sesi_scrim WHERE id_sesi = p_id_sesi;

  IF v_id_scrim IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Sesi tidak ditemukan');
  END IF;

  SELECT juara1_50persen, juara2_30persen, juara3_20persen
  INTO   v_juara1, v_juara2, v_juara3
  FROM   keuangan_scrim WHERE id_scrim = v_id_scrim;

  IF v_juara1 IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Data keuangan scrim belum ada. Pastikan ada peserta yang sudah bayar.'
    );
  END IF;

  -- Ambil 3 besar dari leaderboard
  FOR rec IN
    SELECT   pt.id_pendaftaran,
             SUM(hp.total_poin) AS total_poin_akhir
    FROM     hasil_pertandingan hp
    JOIN     pendaftaran_tim pt ON pt.id_pendaftaran = hp.id_pendaftaran
    WHERE    hp.id_sesi = p_id_sesi
    AND      pt.status_pembayaran::TEXT = 'dikonfirmasi'
    GROUP BY pt.id_pendaftaran
    ORDER BY total_poin_akhir DESC
    LIMIT 3
  LOOP
    v_hadiah := CASE v_rank
      WHEN 1 THEN v_juara1
      WHEN 2 THEN v_juara2
      WHEN 3 THEN v_juara3
      ELSE 0
    END;

    IF NOT EXISTS (
      SELECT 1 FROM klaim_hadiah WHERE id_pendaftaran = rec.id_pendaftaran
    ) THEN
      INSERT INTO klaim_hadiah (id_pendaftaran, status_klaim, jumlah_klaim)
      VALUES (rec.id_pendaftaran, 'belum_diajukan', v_hadiah);
    ELSE
      UPDATE klaim_hadiah
      SET    jumlah_klaim = v_hadiah
      WHERE  id_pendaftaran = rec.id_pendaftaran
      AND    status_klaim   = 'belum_diajukan';
    END IF;

    v_rank := v_rank + 1;
  END LOOP;

  IF v_rank = 1 THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Belum ada skor yang diinput untuk sesi ini.'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Hadiah berhasil dibagikan ke ' || (v_rank - 1) || ' pemenang.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =============================================================
-- BAGIAN 3: VERIFIKASI PELUNASAN UTANG ADMIN OLEH OWNER
-- Dipanggil saat Owner mengklik "Verifikasi" bukti bayar admin.
-- Yang dilakukan otomatis:
--   ① total_utang kembali ke 0
--   ② status akun admin kembali 'aktif'
--   ③ status pelunasan diubah ke 'diverifikasi'
-- =============================================================

CREATE OR REPLACE FUNCTION fn_verifikasi_pelunasan(p_id_pelunasan BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_admin_id INT;
BEGIN
  -- Ambil admin_id dari pelunasan
  SELECT admin_id INTO v_admin_id
  FROM   pelunasan_utang_admin
  WHERE  id_pelunasan = p_id_pelunasan;

  IF v_admin_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Data pelunasan tidak ditemukan');
  END IF;

  -- ① Reset total_utang admin
  UPDATE profil_admin
  SET    total_utang = 0
  WHERE  akun_id = v_admin_id;

  -- ② Aktifkan kembali akun admin
  UPDATE akun
  SET    status_akun = 'aktif'
  WHERE  id_akun = v_admin_id;

  -- ③ Update status pelunasan
  UPDATE pelunasan_utang_admin
  SET    status           = 'diverifikasi',
         diverifikasi_pada = NOW()
  WHERE  id_pelunasan = p_id_pelunasan;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Pelunasan diverifikasi. Akun admin telah diaktifkan kembali.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
