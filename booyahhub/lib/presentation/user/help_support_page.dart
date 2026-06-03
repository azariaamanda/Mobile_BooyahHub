import 'package:flutter/material.dart';
import '../../config/app_color.dart';
import '../../config/app_text_styles.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'BANTUAN & DUKUNGAN',
          style: AppTextStyles.poppinsTitle.copyWith(
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pertanyaan Umum (FAQ)',
              style: AppTextStyles.poppinsSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Bagaimana cara mendaftar turnamen?',
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            ),
            _buildFaqItem(
              'Bagaimana cara klaim hadiah?',
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
            ),
            _buildFaqItem(
              'Apa itu fee platform?',
              'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
            ),
            _buildFaqItem(
              'Bagaimana cara mengubah profil?',
              'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.',
            ),
            _buildFaqItem(
              'Apakah aplikasi ini gratis?',
              'Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.',
            ),
            _buildFaqItem(
              'Bagaimana sistem keamanan data saya?',
              'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.',
            ),
            _buildFaqItem(
              'Di mana saya bisa melihat riwayat turnamen?',
              'Id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est.',
            ),
            _buildFaqItem(
              'Bagaimana cara menjadi admin?',
              'Omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus.',
            ),
            _buildFaqItem(
              'Apakah saya bisa menarik dana kapan saja?',
              'Ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            ),
            _buildFaqItem(
              'Apa saja metode pembayaran yang didukung?',
              'Viverra justo nec ultrices dui sapien eget mi proin sed. Et netus et malesuada fames ac turpis egestas integer eget. Nibh nisl condimentum id venenatis a condimentum vitae. Amet cursus sit amet dictum sit.',
            ),
            _buildFaqItem(
              'Bagaimana jika aplikasi mengalami error?',
              'Sem fringilla ut morbi tincidunt augue interdum velit euismod in. Vitae ultricies leo integer malesuada nunc vel risus commodo. Diam in arcu cursus euismod quis. Tristique magna sit amet purus gravida quis blandit.',
            ),
            _buildFaqItem(
              'Berapa lama proses verifikasi akun?',
              'Faucibus purus in massa tempor nec feugiat. Nisl pretium fusce id velit ut. Sed felis eget velit aliquet sagittis id consectetur purus ut. Dictum fusce ut placerat orci nulla pellentesque dignissim enim sit.',
            ),
            _buildFaqItem(
              'Apa syarat menjadi penyelenggara turnamen?',
              'Amet dictum sit amet justo donec enim diam vulputate. Eu volutpat odio facilisis mauris sit amet massa vitae tortor. In hendrerit gravida rutrum quisque non tellus orci. Eget aliquet nibh praesent tristique magna sit amet.',
            ),
            _buildFaqItem(
              'Bagaimana kebijakan privasi aplikasi ini?',
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
            ),
            _buildFaqItem(
              'Apakah ada batasan umur untuk bermain?',
              'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
            ),
            const SizedBox(height: 32),
            Text(
              'Kebijakan & Syarat Ketentuan',
              style: AppTextStyles.poppinsSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '1. Ketentuan Pengguna\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam in dui mauris. Vivamus hendrerit arcu sed erat molestie vehicula. Sed auctor neque eu tellus rhoncus ut eleifend nibh porttitor. Ut in nulla enim.\n\n'
                '2. Hak & Kewajiban\n\nPhasellus id nulla. Mauris ultricies, nulla sit amet pellentesque porta, velit risus egestas dolor, id imperdiet dolor erat sed mauris. Vestibulum suscipit varius libero sed condimentum.\n\n'
                '3. Pelanggaran\n\nDonec posuere dictum enim. Vivamus quis elit nisl, id mattis velit. Cras tempor, mi at condimentum hendrerit, neque felis mattis leo, ac ullamcorper leo neque a leo.',
                style: AppTextStyles.interCaption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hubungi Kami',
              style: AppTextStyles.poppinsSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Text(
                        'support@booyahhub.com',
                        style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Text(
                        '+62 812-3456-7890',
                        style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Gedung BooyahHub Lt. 42, Jl. Jend. Sudirman Kav. 1, Jakarta Pusat, DKI Jakarta 10220',
                          style: AppTextStyles.interBody.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.interBody.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: AppTextStyles.interCaption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
