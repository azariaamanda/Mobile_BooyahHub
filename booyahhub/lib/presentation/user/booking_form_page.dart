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

  // Controller (tanpa nama_tim)
  final _namaKaptenController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Controller ID Player
  final _idPlayer1Controller = TextEditingController();
  final _idPlayer2Controller = TextEditingController();
  final _idPlayer3Controller = TextEditingController();
  final _idPlayer4Controller = TextEditingController();

  // State
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  String _namaTim = 'Memuat...';

  final List<Map<String, String>> _paymentOptions = [
    {'value': 'bank_transfer', 'label': 'Transfer Bank (BCA)'},
    {'value': 'qris', 'label': 'QRIS Otomatis'},
    {'value': 'ewallet', 'label': 'E-Wallet (Dana/OVO)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ─── AMBIL DATA USER YANG LOGIN ───
  Future<void> _loadUserData() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        setState(() => _namaTim = 'Belum Login');
        return;
      }

      // 1. Cari id_akun dari email
      final akunResponse = await supabase
          .from('akun')
          .select('id_akun')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (akunResponse == null) {
        setState(() => _namaTim = 'Akun tidak ditemukan');
        return;
      }

      final int akunId = akunResponse['id_akun'];

      // 2. Cari profil_pengguna berdasarkan akun_id
      final profilResponse = await supabase
          .from('profil_pengguna')
          .select('nama_tim')
          .eq('akun_id', akunId)
          .maybeSingle();

      setState(() {
        _namaTim = profilResponse?['nama_tim'] ?? 'Tim Saya';
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _namaTim = 'Gagal memuat data');
    }
  }

  @override
  void dispose() {
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
      setState(() => _isLoading = true);

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

        final supabase = Supabase.instance.client;
        final currentUser = supabase.auth.currentUser;

        if (currentUser == null) throw Exception('User tidak login');

        // 1. Cari id_akun dari email user
        final akunResponse = await supabase
            .from('akun')
            .select('id_akun')
            .eq('email', currentUser.email!)
            .maybeSingle();

        if (akunResponse == null) throw Exception('Akun tidak ditemukan');
        final int akunId = akunResponse['id_akun'];

        // 2. Cari id_profil_pengguna (sebagai id_tim)
        final profilResponse = await supabase
            .from('profil_pengguna')
            .select('id_profil_pengguna')
            .eq('akun_id', akunId)
            .maybeSingle();

        if (profilResponse == null) {
          throw Exception('Profil tim tidak ditemukan. Silakan lengkapi profil Anda terlebih dahulu.');
        }
        final int timId = profilResponse['id_profil_pengguna'];

        // 3. INSERT DATA (TANPA 'nama_tim')
        final response = await supabase
            .from('pendaftaran_tim')
            .insert({
              'id_sesi': widget.sesiId,
              'id_tim': timId,
              'akun_id': akunId,
              'nama_kapten': _namaKaptenController.text,
              'whatsapp_kapten': _whatsappController.text,
              'id_player_1': _idPlayer1Controller.text,
              'id_player_2': _idPlayer2Controller.text.isEmpty ? null : _idPlayer2Controller.text,
              'id_player_3': _idPlayer3Controller.text.isEmpty ? null : _idPlayer3Controller.text,
              'id_player_4': _idPlayer4Controller.text.isEmpty ? null : _idPlayer4Controller.text,
              'metode_pembayaran_daftar': _selectedPaymentMethod,
              'status_pembayaran': 'menunggu',
            })
            .select('id_pendaftaran')
            .single();

        if (!mounted) return;
        Navigator.of(context).pop();

        final int idBaruDariSupabase = response['id_pendaftaran'];
        if (!mounted) return;
        context.push('/user/payment/$idBaruDariSupabase', extra: idBaruDariSupabase);

      } catch (error) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pendaftaran: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
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
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
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
              // Top Banner: Info Tim (READ ONLY, dari profil)
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
                    const Icon(Icons.group, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tim Anda', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(_namaTim, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: INFO KAPTEN
              _buildSectionTitle('INFO KAPTEN'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('Nama Kapten'),
                  _buildInputField(controller: _namaKaptenController, hint: 'Nama Lengkap'),
                  const SizedBox(height: 16),
                  _buildFieldLabel('WhatsApp Kapten'),
                  _buildInputField(controller: _whatsappController, hint: '0857-xxxx', keyboardType: TextInputType.phone),
                ],
              ),
              const SizedBox(height: 24),

              // Section 2: ID PLAYER
              _buildSectionTitle('ID PLAYER'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('ID Player 1 (Kapten) *'),
                  _buildInputField(controller: _idPlayer1Controller, hint: 'Masukkan ID Player', isRequired: true),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 2 (Opsional)'),
                  _buildInputField(controller: _idPlayer2Controller, hint: 'Masukkan ID Player (Opsional)', isRequired: false),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 3 (Opsional)'),
                  _buildInputField(controller: _idPlayer3Controller, hint: 'Masukkan ID Player (Opsional)', isRequired: false),
                  const SizedBox(height: 16),
                  _buildFieldLabel('ID Player 4 (Opsional)'),
                  _buildInputField(controller: _idPlayer4Controller, hint: 'Masukkan ID Player (Opsional)', isRequired: false),
                ],
              ),
              const SizedBox(height: 24),

              // Section 3: METODE PEMBAYARAN
              _buildSectionTitle('METODE PEMBAYARAN'),
              const SizedBox(height: 8),
              _buildYellowCard(
                children: [
                  _buildFieldLabel('Pilih Metode Pembayaran'),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    dropdownColor: AppColors.backgroundCard,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A2B38)),
                    selectedItemBuilder: (context) => _paymentOptions.map((option) => Container(
                      alignment: Alignment.centerLeft,
                      child: Text(option['label']!, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                    )).toList(),
                    items: _paymentOptions.map((option) => DropdownMenuItem(
                      value: option['value'],
                      child: Text(option['label']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                    decoration: InputDecoration(
                      hintText: 'Pilih Metode',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF020C15), width: 1.5)),
                    ),
                    validator: (value) => value == null ? 'Silakan pilih metode pembayaran' : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol Selanjutnya
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Selanjutnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(label, style: const TextStyle(color: Color(0xFF1A2B38), fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildYellowCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF020C15), width: 1.5)),
      ),
      validator: isRequired ? (value) => value == null || value.trim().isEmpty ? 'Kolom ini wajib diisi' : null : null,
    );
  }
}