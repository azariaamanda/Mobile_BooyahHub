import 'package:flutter/material.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_image_helper.dart';
import '../../../config/app_text_styles.dart';

class TeamProfileHeader extends StatelessWidget {
  final String namaTim;
  final String fotoProfilName;

  const TeamProfileHeader({
    super.key,
    required this.namaTim,
    required this.fotoProfilName,
  });

  @override
  Widget build(BuildContext context) {
    // Memakai image helper asli tim lu
    final profileUrl = AppImageHelper.fotoProfilByEmail(fotoProfilName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mengganti .between yang error
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary, // Memakai AppColors.primary (Emas Utama)
              backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
              child: profileUrl.isEmpty
                  ? const Icon(Icons.sports_esports, color: AppColors.black)
                  : null,
            ),
            const SizedBox(width: AppConstants.paddingM), // Memakai AppConstants padding
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo,',
                  style: AppTextStyles.interCaption, // Memakai standard caption
                ),
                Text(
                  namaTim,
                  style: AppTextStyles.poppinsTitleSmall, // Memakai standard title small
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}