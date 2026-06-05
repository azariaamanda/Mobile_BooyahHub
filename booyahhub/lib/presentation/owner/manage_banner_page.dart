import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';
import '../../data/models/services/banner_service.dart';
import '../../data/models/banner_model.dart';

class ManageBannerPage extends StatefulWidget {
  const ManageBannerPage({super.key});

  @override
  State<ManageBannerPage> createState() => _ManageBannerPageState();
}

class _ManageBannerPageState extends State<ManageBannerPage> {
  final BannerService _bannerService = BannerService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  bool _isAddingBanner = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imageUrl;
  File? _imageFile;
  bool _isUploading = false;
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    final banners = await _bannerService.getAllBanners();
    setState(() {
      _banners = banners;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} - ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} - ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return const Color(0xFF00FF87);
      case 'draft':
        return const Color(0xFFFFC107);
      case 'expired':
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return 'AKTIF';
      case 'draft':
        return 'DRAFT';
      case 'expired':
        return 'EXPIRED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _uploadAndSaveBanner() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul banner harus diisi')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai dan berakhir harus diisi')),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? finalImageUrl = _imageUrl;
    
    if (_imageFile != null) {
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadedUrl = await BannerService.uploadBannerImage(_imageFile!, fileName);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload gambar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final bannerData = {
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'image_url': finalImageUrl,
      'start_date': _startDate!.toIso8601String(),
      'end_date': _endDate!.toIso8601String(),
      'status': _status,
      'link': _linkController.text.isEmpty ? null : _linkController.text,
      'priority': 0,
    };

    final result = await _bannerService.createBanner(bannerData);
    setState(() => _isUploading = false);

    if (result != null) {
      _resetForm();
      await _loadBanners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan banner'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _subtitleController.clear();
    _linkController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _imageUrl = null;
      _imageFile = null;
      _status = 'draft';
      _isAddingBanner = false;
    });
  }

  Future<void> _activateBanner(BannerModel banner) async {
    final result = await _bannerService.updateBanner(banner.id, {'status': 'aktif'});
    if (result != null) {
      await _loadBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner berhasil diaktifkan'),
            backgroundColor: Colors.green,
          ),
        ); 
      }
    }
  }

  Future<void> _editBanner(BannerModel banner) async {
    _titleController.text = banner.title;
    _subtitleController.text = banner.subtitle;
    _linkController.text = banner.link ?? '';
    _startDate = banner.startDate;
    _endDate = banner.endDate;
    _imageUrl = banner.imageUrl;
    _status = banner.status;
    _imageFile = null;
    
    setState(() => _isAddingBanner = true);
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBannerForm(isEdit: true, banner: banner),
    );
    
    if (result == true) {
      await _loadBanners();
    }
    _resetForm();
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131F2D),
        title: const Text('Hapus Banner?'),
        content: Text('Yakin ingin menghapus banner "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _bannerService.deleteBanner(banner.id);
      if (success && banner.imageUrl.isNotEmpty) {
        await BannerService.deleteBannerImage(banner.imageUrl);
      }
      if (success) {
        await _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
        automaticallyImplyLeading: false,
        title: Text(
          'Kelola Banner',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
            onPressed: () {
              setState(() => _isAddingBanner = true);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildBannerForm(isEdit: false),
              ).then((result) {
                if (result == true) _loadBanners();
                _resetForm();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Peringatan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: const Color(0xFFFFC107), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Peringatan: Menghapus banner aktif akan langsung menghilangkannya dari beranda pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daftar Promosi
                  Text(
                    'Daftar Promosi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List Banner
                  if (_banners.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Icon(Icons.image_outlined, size: 64, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada banner',
                            style: GoogleFonts.poppins(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._banners.map((banner) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildBannerCard(banner),
                    )),
                  
                  const SizedBox(height: 24),

                  // Pratinjau di beranda
                  Text(
                    'Pratinjau di beranda',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerCard(BannerModel banner) {
    final isAktif = banner.status.toLowerCase() == 'aktif';
    final isExpired = banner.status.toLowerCase() == 'expired';
    final isDraft = banner.status.toLowerCase() == 'draft';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: banner.imageUrl.isNotEmpty
                    ? Image.network(
                        banner.imageUrl,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: const Color(0xFF0A1A26),
                            child: Center(
                              child: Text(
                                banner.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: const Color(0xFF0A1A26),
                        child: Center(
                          child: Text(
                            banner.title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(banner.status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(banner.status),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isAktif ? Colors.black : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateShort(banner.startDate),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    if (isDraft)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _activateBanner(banner),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFD700)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Aktifkan',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),
                    if (isDraft) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _editBanner(banner),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deleteBanner(banner),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFFF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final activeBanners = _banners.where((b) => b.status.toLowerCase() == 'aktif').toList();
    final previewBanner = activeBanners.isNotEmpty ? activeBanners.first : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131F2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewBanner != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: previewBanner.imageUrl.isNotEmpty
                  ? Image.network(
                      previewBanner.imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: const Color(0xFF0A1A26),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  previewBanner.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  previewBanner.subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 150,
                      color: const Color(0xFF0A1A26),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              previewBanner.title,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              previewBanner.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDateShort(previewBanner.startDate),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          if (previewBanner == null)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Tidak ada banner aktif',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Tampilan banner pada aplikasi pengguna',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerForm({required bool isEdit, BannerModel? banner}) {
    final isEditing = isEdit && banner != null;
    
    if (isEditing) {
      _titleController.text = banner!.title;
      _subtitleController.text = banner.subtitle;
      _linkController.text = banner.link ?? '';
      _startDate = banner.startDate;
      _endDate = banner.endDate;
      _imageUrl = banner.imageUrl;
      _status = banner.status;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131F2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Edit Banner' : 'Tambah Banner Baru',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1A26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : _imageUrl != null && _imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.white54, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk pilih gambar',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Judul Banner',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0A1A26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            TextField(
              controller: _subtitleController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Subtitle (opsional)',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0A1A26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Start Date & End Date
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFFFFD700)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1A26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                  : 'Mulai',
                              style: GoogleFonts.poppins(
                                color: _startDate != null ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: Color(0xFFFFD700)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1A26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _endDate != null
                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                  : 'Selesai',
                              style: GoogleFonts.poppins(
                                color: _endDate != null ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Link
            TextField(
              controller: _linkController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Link (opsional)',
                labelStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0A1A26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = 'draft'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _status == 'draft' ? const Color(0xFFFFC107) : const Color(0xFF0A1A26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Draft',
                          style: GoogleFonts.poppins(
                            color: _status == 'draft' ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = 'aktif'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _status == 'aktif' ? const Color(0xFF00FF87) : const Color(0xFF0A1A26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Aktif',
                          style: GoogleFonts.poppins(
                            color: _status == 'aktif' ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndSaveBanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        isEditing ? 'Update Banner' : 'Simpan Banner',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}