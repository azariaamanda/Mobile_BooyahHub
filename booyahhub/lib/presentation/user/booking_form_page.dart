import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingFormPage extends StatefulWidget {
  final int sesiId;

  const BookingFormPage({super.key, required this.sesiId});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller Info Tim
  final _namaTimController = TextEditingController();
  final _namaKaptenController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Controller ID Player
  final _idPlayer1Controller = TextEditingController();
  final _idPlayer2Controller = TextEditingController();
  final _idPlayer3Controller = TextEditingController();
  final _idPlayer4Controller = TextEditingController();

  // State untuk menyimpan metode pembayaran yang dipilih user
  String? _selectedPaymentMethod;

  // Daftar opsi metode pembayaran (sesuaikan dengan isi ENUM database lu bray)
  final List<Map<String, String>> _paymentOptions = [
    {'value': 'bank_transfer', 'label': 'Transfer Bank (BCA)'},
    {'value': 'qris', 'label': 'QRIS Otomatis'},
    {'value': 'ewallet', 'label': 'E-Wallet (Dana/OVO)'},
  ];

  @override
  void dispose() {
    _namaTimController.dispose();
    _namaKaptenController.dispose();
    _whatsappController.dispose();
    _idPlayer1Controller.dispose();
    _idPlayer2Controller.dispose();
    _idPlayer3Controller.dispose();
    _idPlayer4Controller.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Munculkan loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

        final supabase = Supabase.instance.client;

        // INSERT DATA KE pendaftaran_tim
        final response = await supabase
            .from('pendaftaran_tim')
            .insert({
              'id_sesi': widget.sesiId, // Menggunakan parameter asli yang dilempar ke halaman
              'id_tim': 1, // Sesuaikan dengan logika id_tim pengguna lu bray
              'nama_kapten': _namaKaptenController.text,
              'whatsapp_kapten': _whatsappController.text,
              'id_player_1': _idPlayer1Controller.text,
              'id_player_2': _idPlayer2Controller.text,
              'id_player_3': _idPlayer3Controller.text,
              'id_player_4': _idPlayer4Controller.text,
              // Mengambil value dinamis dari pilihan user di UI
              'metode_pembayaran_daftar': _selectedPaymentMethod, 
            })
            .select('id_pendaftaran')
            .single();

        // Tutup loading dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        // Ambil nilai ID pendaftaran asli hasil generate database
        final int idBaruDariSupabase = response['id_pendaftaran'];

        // Navigasi ke halaman payment checkout bawa ID baru
        if (!mounted) return;
        context.push('/user/payment/$idBaruDariSupabase', extra: idBaruDariSupabase);

      } catch (error) {
        // Tutup loading dialog jika terjadi kegagalan
        if (!mounted) return;
        Navigator.of(context).pop();

        // Tampilkan pesan eror lengkap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pendaftaran: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pendaftaran Tim',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Banner: Slot Dipilih ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Slot dipilih: Sesi ID ${widget.sesiId}',
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Section 1: INFO TIM ────────────────────────────────
              _buildSectionTitle('INFO TIM'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('Nama Tim'),
                  _buildInputField(controller: _namaTimController, hint: 'Nama'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('Nama Kapten'),
                  _buildInputField(controller: _namaKaptenController, hint: 'Nama Lengkap'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('WhatsApp Kapten'),
                  _buildInputField(
                    controller: _whatsappController, 
                    hint: '0857-xxxx', 
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Section 2: ID PLAYER ───────────────────────────────
              _buildSectionTitle('ID PLAYER'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('ID Player 1 (Kapten)'),
                  _buildInputField(controller: _idPlayer1Controller, hint: 'Masukkan ID Player'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 2'),
                  _buildInputField(controller: _idPlayer2Controller, hint: 'Masukkan ID Player'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 3'),
                  _buildInputField(controller: _idPlayer3Controller, hint: 'Masukkan ID Player'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 4'),
                  _buildInputField(controller: _idPlayer4Controller, hint: 'Masukkan ID Player'),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Section 3: METODE PEMBAYARAN ───────────────────────
              _buildSectionTitle('METODE PEMBAYARAN'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('Pilih Metode Pembayaran'),
                  DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  dropdownColor: AppColors.backgroundCard, // Pop-up list pake background gelap lu bray
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A2B38)), // Icon disamain sama warna label biar kontras
                  
                  // 1. INI KUNCINYA BRAY! Ngatur tampilan teks SETELAH dipilih (di dalam kotak putih)
                  selectedItemBuilder: (BuildContext context) {
                    return _paymentOptions.map<Widget>((option) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          option['label']!,
                          style: const TextStyle(
                            color: Colors.black87, // Teks jadi hitam/gelap pas udah kepilih di kotak putih!
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  
                  // 2. Ini tampilan PAS POP-UP LIST DIKLIK/MUNCUL (di luar kotak putih)
                  items: _paymentOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(
                        option['label']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary, // Tetep putih biar kontras di background gelap list-nya
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Pilih Metode',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3), // Kotak input tetep putih bersih serasi ama field atas
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF020C15), width: 1.5),
                    ),
                    errorStyle: const TextStyle(color: Color(0xFF8B1A00), fontWeight: FontWeight.bold),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan pilih metode pembayaran bray';
                    }
                    return null;
                  },
                )
                ],
              ),
              const SizedBox(height: 32),

              // ─── Tombol Selanjutnya ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Selanjutnya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Judul Section Kategori
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  // Helper: Label Input di Dalam Kartu Kuning
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1A2B38),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper: Wadah Kartu Berwarna Emas Utama
  Widget _buildYellowCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Helper: Komponen Input Field Putih
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF020C15), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFF8B1A00), fontWeight: FontWeight.bold),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Kolom ini wajib diisi bray';
        }
        return null;
      },
    );
  }
}