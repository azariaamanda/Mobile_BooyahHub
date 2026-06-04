import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/paket_premium_model.dart';

class EditPremiumPackageScreen extends StatefulWidget {
  final PaketPremiumModel? package;

  const EditPremiumPackageScreen({super.key, this.package});

  @override
  State<EditPremiumPackageScreen> createState() => _EditPremiumPackageScreenState();
}

class _EditPremiumPackageScreenState extends State<EditPremiumPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  
  // Form controllers
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _durasiController = TextEditingController();

  // State variables
  // State variables
  String _selectedTier = 'PRO LEVEL';
  bool _isAktif = true;

  // Features state
  // Using dynamic loading from Supabase RPC
  Map<String, bool> _featuresState = {};
  bool _isLoadingFeatures = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (widget.package != null) {
      final pkg = widget.package!;
      _namaController.text = pkg.namaPaket;
      _hargaController.text = pkg.harga?.toInt().toString() ?? '';
      _durasiController.text = pkg.durasiHari?.toString() ?? '30';
      _selectedTier = pkg.tierLevel ?? 'PRO LEVEL';
      _isAktif = pkg.status?.toLowerCase() == 'aktif';
    } else {
      _durasiController.text = '30';
    }

    // Fetch dynamic enum values
    try {
      final response = await _supabase.rpc('get_fitur_paket_enum');
      if (response != null && response is List) {
        final Map<String, bool> fetchedFeatures = {};
        for (var feature in response) {
          final featureStr = feature.toString();
          // Check if this feature is already selected in the existing package
          bool isSelected = false;
          if (widget.package != null && widget.package!.fiturPaket != null) {
            isSelected = widget.package!.fiturPaket!.contains(featureStr);
          }
          fetchedFeatures[featureStr] = isSelected;
        }
        
        if (mounted) {
          setState(() {
            _featuresState = fetchedFeatures;
            _isLoadingFeatures = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching enum features: $e');
      if (mounted) {
        setState(() => _isLoadingFeatures = false);
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _durasiController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Gather selected features into an array of strings (using the Enum values)
      List<String> selectedFeatures = [];
      _featuresState.forEach((key, isChecked) {
        if (isChecked) {
          selectedFeatures.add(key);
        }
      });

      final payload = {
        'nama_paket': _namaController.text,
        'tier_level': _selectedTier,
        'harga': double.tryParse(_hargaController.text) ?? 0,
        'durasi_hari': int.tryParse(_durasiController.text) ?? 30,
        'status': _isAktif ? 'aktif' : 'nonaktif',
        'fitur_paket': selectedFeatures,
      };

      if (widget.package == null) {
        // Create new
        await _supabase.from('paket_premium').insert(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paket berhasil ditambahkan!')),
          );
        }
      } else {
        // Update existing
        await _supabase
            .from('paket_premium')
            .update(payload)
            .eq('id_langganan', widget.package!.idLangganan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paket berhasil diperbarui!')),
          );
        }
      }

      if (mounted) {
        context.pop(); // Go back
      }
    } catch (e) {
      debugPrint('Error saving package: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.package == null ? 'Tambah Paket Premium' : 'Edit Paket Premium',
          style: AppTextStyles.poppinsHeadline.copyWith(
            color: const Color(0xFFFFD700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningAlert(),
              const SizedBox(height: 24),
              _buildLabel('NAMA PAKET PREMIUM'),
              _buildTextField(
                controller: _namaController,
                hint: 'Contoh: Elite Commander',
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _buildLabel('TIER LEVEL'),
              _buildTierDropdown(),
              const SizedBox(height: 24),
              _buildLabel('FITUR PAKET'),
              ..._featuresState.keys.map((featureName) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildFeatureItem(
                    title: featureName,
                    isChecked: _featuresState[featureName]!,
                    onTap: () {
                      setState(() {
                        _featuresState[featureName] = !_featuresState[featureName]!;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
              _buildLabel('HARGA (RP)'),
              _buildPriceField(),
              const SizedBox(height: 24),
              _buildLabel('DURASI PAKET (HARI)'),
              _buildTextField(
                controller: _durasiController,
                hint: 'Contoh: 30',
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Durasi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _buildStatusSwitch(),
              const SizedBox(height: 32),
              _buildActionButtons(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A191B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF8B4747),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.priority_high_rounded, color: Color(0xFF2A191B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peringatan Transaksi',
                  style: AppTextStyles.interBody.copyWith(
                    color: const Color(0xFFD67777),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon lengkapi semua field yang diperlukan sebelum menyimpan perubahan',
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: AppTextStyles.interCaption.copyWith(
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.interBody.copyWith(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.interBody.copyWith(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF131F2D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildTierDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTier,
          isExpanded: true,
          dropdownColor: const Color(0xFF131F2D),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFD700)),
          style: AppTextStyles.interBody.copyWith(color: Colors.white, fontSize: 14),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedTier = newValue);
            }
          },
          items: <String>['PRO LEVEL', 'TEAM SCALE', 'ENTRY LEVEL', 'UMUM']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required String title, required bool isChecked, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131F2D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isChecked ? const Color(0xFFFFD700) : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.interBody.copyWith(
                  color: isChecked ? Colors.white : Colors.white54,
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (isChecked)
              const Icon(Icons.check_rounded, color: Color(0xFFFFD700), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _hargaController,
      keyboardType: TextInputType.number,
      validator: (val) => val == null || val.isEmpty ? 'Harga tidak boleh kosong' : null,
      style: AppTextStyles.interBody.copyWith(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: AppTextStyles.interBody.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PER PERIODE',
                  style: AppTextStyles.interCaption.copyWith(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFF131F2D),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Paket',
                  style: AppTextStyles.interBody.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'tentukan visibilitas paket di beranda',
                  style: AppTextStyles.interCaption.copyWith(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isAktif = !_isAktif),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 24,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _isAktif ? const Color(0xFFFFD700) : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: _isAktif ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _isAktif ? const Color(0xFF0F1722) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isAktif ? 'AKTIF' : 'NONAKTIF',
                  style: AppTextStyles.interCaption.copyWith(
                    color: _isAktif ? const Color(0xFFFFD700) : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _savePackage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.5),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
              )
            : Text(
              widget.package == null ? 'TAMBAH PAKET' : 'SIMPAN PAKET',
              style: AppTextStyles.poppinsTitleSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F1722),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'BATAL',
            style: AppTextStyles.poppinsTitleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
