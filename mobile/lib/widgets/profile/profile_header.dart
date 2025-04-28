import  'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../styles/colors.dart';

class ProfileHeader extends StatelessWidget {
  final User user;

  const ProfileHeader({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          Hero(
            tag: 'profileAvatar',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryColor, width: 2),
                image: DecorationImage(
                  image: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.username ?? 'Użytkownik',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getUserRoleTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.location ?? 'Brak lokalizacji',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  String _getUserRoleTitle() {
    final level = user.level ?? 1;

    if (level >= 10) return 'Opiekun Zwierząt 🌟';
    if (level >= 7) return 'Przyjaciel Schroniska 🏆';
    if (level >= 5) return 'Aktywny Pomocnik 🔥';
    if (level >= 3) return 'Początkujący Wolontariusz 🌱';
    return 'Nowy Użytkownik 😊';
  }
}