import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_color.dart';

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

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      // TODO: Integrasikan ke Supabase pendaftaran_tim menggunakan widget.sesiId
      
      // Setelah sukses, arahkan ke halaman checkout pembayaran
      context.push('/user/payment/123');
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
                        'Slot dipilih: 7 April, 08.00 - 09.00',
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