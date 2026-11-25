import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:zelvira/components/notifcation_widget.dart';
import '../models/product_model.dart';
import '../pages/product/product_detail_page.dart';
import '../config/url_utils.dart';
import '../config/currency_utils.dart';
import '../riverpod/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product? product; // Add this
  final String image;
  final String title;
  final String brand;
  final String? description;
  final double price;
  final double? originalPrice;
  final double rating;
  final List<String>? sizes;
  final List<String>? colorHexes;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const ProductCard({
    super.key,
    this.product,
    required this.image,
    required this.title,
    required this.brand,
    this.description,
    required this.price,
    this.originalPrice,
    this.rating = 0.0,
    this.sizes,
    this.colorHexes,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool wishlisted = product != null
        ? ref.watch(isProductWishlistedProvider(product!.id))
        : isFavorite;

    // Use calculated rating from product API (reviews) if product is available
    final double finalRating = product?.averageRating != null
        ? product!.averageRating!
        : rating;
    final int reviewCount = product?.reviewCount ?? 0;

    return GestureDetector(
      onTap: () {
        // Collect all available banners, variant images, and thumbnail
        final List<String> detailImages = [];
        if (product != null) {
          if (product!.images != null && product!.images!.isNotEmpty) {
            detailImages.addAll(product!.images!);
          } else if (product!.imageUrl != null &&
              product!.imageUrl!.isNotEmpty) {
            detailImages.add(product!.imageUrl!);
          }
          // Add variant specific images if present
          for (final v in product!.variants) {
            if (v.imageUrl != null &&
                v.imageUrl!.isNotEmpty &&
                !detailImages.contains(v.imageUrl)) {
              detailImages.add(v.imageUrl!);
            }
          }
        }
        if (detailImages.isEmpty) {
          detailImages.add(image);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              images: detailImages,
              title: title,
              brand: brand,
              price: price,
              originalPrice: originalPrice,
              rating: finalRating,
              description: description,
              stock: product?.totalStock ?? 85,
              soldCount: 120,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              flex: 12,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CustomNetworkImage(
                        UrlUtils.formatImageUrl(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        if (onFavoriteTap != null) {
                          onFavoriteTap!();
                        } else if (product != null) {
                          try {
                            final added = await ref
                                .read(wishlistProvider.notifier)
                                .toggleWishlist(product!);
                            if (context.mounted) {
                              AppToast.success(
                                context,
                                added
                                    ? 'Ditambahkan ke Wishlist'
                                    : 'Dihapus dari Wishlist',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(
                                context,
                                'Gagal memperbarui wishlist: $e',
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: wishlisted
                              ? const Color(0xFFFFECEE)
                              : Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: wishlisted
                              ? Border.all(color: Colors.red.shade300, width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: wishlisted
                                  ? Colors.red.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: wishlisted ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          wishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: wishlisted
                              ? const Color(0xFFFF1744)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              flex: 15,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand
                    Text(
                      brand,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),

                    // Title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Deskripsi 2 baris
                    if (description != null)
                      Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Rating calculated from reviews
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          finalRating > 0
                              ? finalRating.toStringAsFixed(1)
                              : '-',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviewCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            "($reviewCount)",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price with automatic wrap to prevent overflow
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          CurrencyUtils.format(price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (originalPrice != null)
                          Text(
                            CurrencyUtils.format(originalPrice),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSizeBadge(String size) {
  //   return Container(
  //     margin: const EdgeInsets.only(right: 4),
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.shade300),
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //     child: Text(size, style: const TextStyle(fontSize: 8)),
  //   );
  // }

  // Widget _buildMoreBadge(int count) {
  //   return Container(
  //     margin: const EdgeInsets.only(right: 4),
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.shade300),
  //       borderRadius: BorderRadius.circular(4),
  //       color: Colors.grey.shade50,
  //     ),
  //     child: Text(
  //       '+$count',
  //       style: const TextStyle(fontSize: 8, color: Colors.grey),
  //     ),
  //   );
  // }

  // Widget _buildColorDot(String hex) {
  //   return Container(
  //     margin: const EdgeInsets.only(right: 4),
  //     width: 10,
  //     height: 10,
  //     decoration: BoxDecoration(
  //       color: _hexToColor(hex),
  //       shape: BoxShape.circle,
  //       border: Border.all(color: Colors.grey.shade200, width: 0.5),
  //     ),
  //   );
  // }

  // Widget _buildMoreText(int count) {
  //   return Text(
  //     '+$count',
  //     style: const TextStyle(fontSize: 8, color: Colors.grey),
  //   );
  // }
}
