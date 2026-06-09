import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_color.dart';
import '../../../config/app_constants.dart';
import '../../../config/app_text_styles.dart';

class TeamProfileHeader extends StatelessWidget {
  final String namaTim;
  final String? fotoProfilUrl;

  const TeamProfileHeader({
    super.key,
    required this.namaTim,
    this.fotoProfilUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mengganti .between yang error
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                backgroundImage: (fotoProfilUrl != null && fotoProfilUrl!.isNotEmpty) ? NetworkImage(fotoProfilUrl!) : null,
                child: (fotoProfilUrl == null || fotoProfilUrl!.isEmpty)
                    ? Text(
                        namaTim.isNotEmpty ? namaTim.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppConstants.paddingM),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo,', style: AppTextStyles.interCaption),
                    Text(
                      namaTim,
                      style: AppTextStyles.poppinsTitleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
          onPressed: () {
            context.pushNamed('notifikasi');
          },
        ),
      ],
    );
  }
}