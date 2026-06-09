-- Aktifkan RLS (jika belum)
ALTER TABLE public.metode_pembayaran_penyelenggara ENABLE ROW LEVEL SECURITY;

-- Hapus policy SELECT yang lama (yang mungkin terlalu ketat)
DROP POLICY IF EXISTS "Enable read access for all users" ON public.metode_pembayaran_penyelenggara;
DROP POLICY IF EXISTS "Public can view payment methods" ON public.metode_pembayaran_penyelenggara;

-- Buat policy baru yang mengizinkan SEMUA ORANG (termasuk anon) untuk membaca metode pembayaran
CREATE POLICY "Public can view payment methods" 
ON public.metode_pembayaran_penyelenggara 
FOR SELECT 
USING (true);
