import 'package:skeletonizer/skeletonizer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../riverpod/home_provider.dart';
import '../card_widget.dart';
import '../error_retry_widget.dart';

/// Returns a Sliver — must be placed directly in a CustomScrollView slivers list
/// or wrapped in SliverMainAxisGroup / SliverPadding.
class HomeFeaturedGrid extends ConsumerWidget {
  const HomeFeaturedGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(homeFeaturedProductsProvider);

    return featuredAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return _shimmerGrid();
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.60,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];

            final imageUrl =
                (product.images != null && product.images!.isNotEmpty)
                ? product.images!.first
                : (product.imageUrl ?? '');

            final hasDiscount =
                product.discountPrice != null && product.discountPrice! > 0;
            final double displayPrice = hasDiscount
                ? product.discountPrice!
                : product.price;
            final double? displayOriginalPrice = hasDiscount
                ? product.price
                : null;

            return ProductCard(
              product: product,
              image: imageUrl,
              title: product.name,
              brand: 'Zelvira',
              price: displayPrice,
              originalPrice: displayOriginalPrice,
              rating: product.rating,
              description: product.shortDescription ?? product.description,
              sizes: product.variants
                  .map((v) => v.size ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet()
                  .toList(),
              colorHexes: product.variants
                  .map((v) => v.hexColor ?? '')
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList(),
            );
          }, childCount: products.length),
        );
      },
      loading: () => Skeletonizer.sliver(enabled: true, child: _shimmerGrid()),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorRetryWidget(
          height: 160,
          onRetry: () => ref.refresh(homeFeaturedProductsProvider),
        ),
      ),
    );
  }

  SliverGrid _shimmerGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.65),
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: 4),
    );
  }
}
