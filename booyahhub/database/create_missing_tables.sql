-- =============================================================
-- TABEL YANG DIBUTUHKAN TRIGGER fn_auto_keuangan_scrim
-- Jalankan di Supabase → SQL Editor → New Query → Run
-- =============================================================

-- ── 1. keuangan_scrim ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS keuangan_scrim (
  id_keuangan          BIGSERIAL   PRIMARY KEY,
  id_scrim             INT         NOT NULL UNIQUE REFERENCES scrim(id_scrim) ON DELETE CASCADE,
  total_pendaftaran    NUMERIC     NOT NULL DEFAULT 0,
  fee_platform_5persen NUMERIC     NOT NULL DEFAULT 0,
  fee_admin_10persen   NUMERIC     NOT NULL DEFAULT 0,
  sisa_hadiah          NUMERIC     NOT NULL DEFAULT 0,
  juara1_50persen      NUMERIC     NOT NULL DEFAULT 0,
  juara2_30persen      NUMERIC     NOT NULL DEFAULT 0,
  juara3_20persen      NUMERIC     NOT NULL DEFAULT 0,
  diperbarui_pada      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE keuangan_scrim ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='keuangan_scrim' AND policyname='keuangan_scrim_all'
  ) THEN
    CREATE POLICY keuangan_scrim_all ON keuangan_scrim
      FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;


-- ── 2. transaksi_fee_admin ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS transaksi_fee_admin (
  id_transaksi       BIGSERIAL   PRIMARY KEY,
  admin_id           INT         NOT NULL REFERENCES akun(id_akun) ON DELETE CASCADE,
  nominal            NUMERIC     NOT NULL DEFAULT 0,
  jumlah_slot        INT         NOT NULL DEFAULT 1,
  sisa_limit_setelah NUMERIC     NOT NULL DEFAULT 0,
  dicatat_pada       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE transaksi_fee_admin ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='transaksi_fee_admin' AND policyname='transaksi_fee_admin_all'
  ) THEN
    CREATE POLICY transaksi_fee_admin_all ON transaksi_fee_admin
      FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;


-- ── 3. Verifikasi ──────────────────────────────────────────────
SELECT 'keuangan_scrim'      AS tabel, COUNT(*) AS baris FROM keuangan_scrim
UNION ALL
SELECT 'transaksi_fee_admin', COUNT(*) FROM transaksi_fee_admin;
