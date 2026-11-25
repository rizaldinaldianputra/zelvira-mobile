import 'package:flutter/material.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_style.dart';
import '../../config/feature_ids.dart';
import '../common/feature_overlay_prompt.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ZelixaFeatureOverlay(
      featureId: FeatureIds.search,
      tapTarget: const Icon(Icons.search, color: AppColors.primary),
      title: 'Pencarian Cepat',
      description:
          'Cari pakaian, aksesoris, dan koleksi fesyen impian Anda dengan cepat dan mudah.',
      step: 1,
      contentLocation: ContentLocation.below,
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 12),
              Text(
                'Search products...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
