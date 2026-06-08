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


-- =============================================================
-- BAGIAN 4: TABEL NOTIFIKASI + RLS + REALTIME
<<<<<<< Updated upstream
-- Jalankan bagian ini di Supabase SQL Editor
=======
>>>>>>> Stashed changes
-- =============================================================

CREATE TABLE IF NOT EXISTS notifikasi (
  id_notifikasi  BIGSERIAL   PRIMARY KEY,
  tipe           VARCHAR(50) NOT NULL,
  judul          TEXT        NOT NULL,
  pesan          TEXT        NOT NULL,
<<<<<<< Updated upstream
  target_role    VARCHAR(20),               -- 'pengguna' / 'admin' / NULL = spesifik user
  target_id_akun INT REFERENCES akun(id_akun) ON DELETE CASCADE,
  data           JSONB       DEFAULT '{}',
  sudah_dibaca   BOOLEAN     DEFAULT FALSE,
  dikirim_pada   TIMESTAMPTZ DEFAULT NOW()  -- nama kolom sesuai kode Flutter
);

CREATE INDEX IF NOT EXISTS idx_notifikasi_target
  ON notifikasi(target_id_akun, target_role, dikirim_pada DESC);

-- Aktifkan Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifikasi;

-- RLS: semua user terautentikasi boleh baca
=======
  target_role    VARCHAR(20),                      -- 'pengguna' / 'admin' / NULL = spesifik user
  target_id_akun INT REFERENCES akun(id_akun) ON DELETE CASCADE,
  data           JSONB       DEFAULT '{}',
  sudah_dibaca   BOOLEAN     DEFAULT FALSE,
  dibuat_pada    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifikasi_target
  ON notifikasi(target_id_akun, target_role, dibuat_pada DESC);

-- Aktifkan Realtime agar Flutter bisa subscribe live updates
ALTER PUBLICATION supabase_realtime ADD TABLE notifikasi;

-- RLS: semua user terautentikasi boleh baca (filter dilakukan di Flutter)
>>>>>>> Stashed changes
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
<<<<<<< Updated upstream
    SELECT 1 FROM pg_policies
    WHERE tablename='notifikasi' AND policyname='notifikasi_read_all'
=======
    SELECT 1 FROM pg_policies WHERE tablename='notifikasi' AND policyname='notifikasi_read_all'
>>>>>>> Stashed changes
  ) THEN
    CREATE POLICY notifikasi_read_all
      ON notifikasi FOR SELECT TO authenticated USING (true);
  END IF;
END $$;


-- =============================================================
-- BAGIAN 5: TRIGGER AUTO-NOTIFIKASI
-- =============================================================

-- ── 5A: Scrim baru → notif ke semua pengguna ─────────────────
CREATE OR REPLACE FUNCTION fn_notif_scrim_baru()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifikasi (tipe, judul, pesan, target_role, data)
  VALUES (
    'scrim_baru',
    'Scrim Baru Tersedia!',
    'Scrim "' || NEW.nama_scrim || '" baru saja ditambahkan. Daftar sekarang!',
    'pengguna',
    jsonb_build_object('id_scrim', NEW.id_scrim, 'nama_scrim', NEW.nama_scrim)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notif_scrim_baru ON scrim;
CREATE TRIGGER trg_notif_scrim_baru
  AFTER INSERT ON scrim
  FOR EACH ROW
  EXECUTE FUNCTION fn_notif_scrim_baru();


-- ── 5B: Pendaftaran masuk → notif ke admin scrim ─────────────
CREATE OR REPLACE FUNCTION fn_notif_pembayaran_masuk()
RETURNS TRIGGER AS $$
DECLARE
  v_id_admin   INT;
  v_nama_scrim TEXT;
  v_nama_tim   TEXT;
  v_id_scrim   INT;
BEGIN
  SELECT s.id_admin, s.nama_scrim, s.id_scrim
  INTO   v_id_admin, v_nama_scrim, v_id_scrim
  FROM   sesi_scrim ss
  JOIN   scrim s ON s.id_scrim = ss.id_scrim
  WHERE  ss.id_sesi = NEW.id_sesi;

  SELECT pp.nama_tim INTO v_nama_tim
  FROM   profil_pengguna pp
  WHERE  pp.akun_id = NEW.akun_id
  LIMIT  1;

  IF v_id_admin IS NOT NULL THEN
    INSERT INTO notifikasi (tipe, judul, pesan, target_id_akun, data)
    VALUES (
      'pembayaran_masuk',
      'Pembayaran Baru Menunggu',
<<<<<<< Updated upstream
      COALESCE(v_nama_tim, 'Tim baru') || ' mendaftar scrim "' ||
        COALESCE(v_nama_scrim, '') || '". Verifikasi sekarang.',
=======
      COALESCE(v_nama_tim, 'Tim baru') || ' mendaftar scrim "' || COALESCE(v_nama_scrim, '') || '". Verifikasi sekarang.',
>>>>>>> Stashed changes
      v_id_admin,
      jsonb_build_object(
        'id_pendaftaran', NEW.id_pendaftaran,
        'id_scrim',       v_id_scrim
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notif_pembayaran_masuk ON pendaftaran_tim;
CREATE TRIGGER trg_notif_pembayaran_masuk
  AFTER INSERT ON pendaftaran_tim
  FOR EACH ROW
  EXECUTE FUNCTION fn_notif_pembayaran_masuk();


-- ── 5C: Status pembayaran berubah → notif ke user ────────────
CREATE OR REPLACE FUNCTION fn_notif_status_pembayaran()
RETURNS TRIGGER AS $$
DECLARE
  v_nama_scrim TEXT;
BEGIN
  IF NEW.status_pembayaran::TEXT = OLD.status_pembayaran::TEXT THEN
    RETURN NEW;
  END IF;

  IF NEW.status_pembayaran::TEXT NOT IN ('dikonfirmasi', 'ditolak') THEN
    RETURN NEW;
  END IF;

  SELECT s.nama_scrim INTO v_nama_scrim
  FROM   sesi_scrim ss
  JOIN   scrim s ON s.id_scrim = ss.id_scrim
  WHERE  ss.id_sesi = NEW.id_sesi;

  IF NEW.status_pembayaran::TEXT = 'dikonfirmasi' THEN
    INSERT INTO notifikasi (tipe, judul, pesan, target_id_akun, data)
    VALUES (
      'pembayaran_dikonfirmasi',
      'Pembayaran Dikonfirmasi',
<<<<<<< Updated upstream
      'Pendaftaran kamu untuk scrim "' || COALESCE(v_nama_scrim, '') ||
        '" telah dikonfirmasi!',
=======
      'Pendaftaran kamu untuk scrim "' || COALESCE(v_nama_scrim, '') || '" telah dikonfirmasi!',
>>>>>>> Stashed changes
      NEW.akun_id,
      jsonb_build_object('id_pendaftaran', NEW.id_pendaftaran)
    );
  ELSE
    INSERT INTO notifikasi (tipe, judul, pesan, target_id_akun, data)
    VALUES (
      'pembayaran_ditolak',
      'Pembayaran Ditolak',
<<<<<<< Updated upstream
      'Pendaftaran kamu untuk scrim "' || COALESCE(v_nama_scrim, '') ||
        '" ditolak. Hubungi admin.',
=======
      'Pendaftaran kamu untuk scrim "' || COALESCE(v_nama_scrim, '') || '" ditolak. Hubungi admin.',
>>>>>>> Stashed changes
      NEW.akun_id,
      jsonb_build_object('id_pendaftaran', NEW.id_pendaftaran)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notif_status_pembayaran ON pendaftaran_tim;
CREATE TRIGGER trg_notif_status_pembayaran
  AFTER UPDATE ON pendaftaran_tim
  FOR EACH ROW
  EXECUTE FUNCTION fn_notif_status_pembayaran();

<<<<<<< Updated upstream
=======

-- =============================================================
-- BAGIAN 6: TABEL FCM TOKENS (push notification background)
-- =============================================================

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id          BIGSERIAL   PRIMARY KEY,
  akun_id     INT         NOT NULL REFERENCES akun(id_akun) ON DELETE CASCADE,
  token       TEXT        NOT NULL,
  platform    VARCHAR(10) DEFAULT 'android',
  dibuat_pada TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(akun_id, platform)
);

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename='fcm_tokens' AND policyname='fcm_tokens_manage'
  ) THEN
    CREATE POLICY fcm_tokens_manage
      ON fcm_tokens FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;
>>>>>>> Stashed changes
