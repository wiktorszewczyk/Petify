import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pet.dart';
import '../../styles/colors.dart';

class PetMiniCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const PetMiniCard({
    Key? key,
    required this.pet,
    this.onTap,
    this.onRemove,
  }) : super(key: key);

  String _formatAge(int age) {
    if (age == 1) return 'rok';
    if (age >= 2 && age <= 4) return 'lata';
    return 'lat';
  }

  Widget _buildPetImage() {
    final imageUrl = pet.imageUrlSafe;

    // Sprawdź czy mamy imageUrl
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // Obsługa URL images (nowy format z backend)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
      );
    }

    // Obsługa lokalnych assetów (placeholder)
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // Fallback
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.pets,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'pet_mini_${pet.id}',
                    child: _buildPetImage(),
                  ),
                  if (pet.isUrgent)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PILNY',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pet.age} ${_formatAge(pet.age)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    pet.breed ?? 'Nieznana rasa',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  if (pet.distance != null)
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 11, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${pet.distance} km',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[600]),
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
}