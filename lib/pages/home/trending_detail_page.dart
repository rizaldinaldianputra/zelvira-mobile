import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/card_widget.dart';
import '../../components/custom_network_image.dart';
import '../../models/content_section_model.dart';
import '../../models/product_model.dart';
import '../../riverpod/home_provider.dart';

class TrendingDetailPage extends ConsumerWidget {
  final ContentItem item;

  const TrendingDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(homeFeaturedProductsProvider);

    // Extract products assigned to this trending item
    List<Product> products = [];
    if (item.products != null && item.products!.isNotEmpty) {
      products = item.products!;
    } else if (item.product != null) {
      products = [item.product!];
    } else {
      // Fallback if no specific products yet
      products = featuredAsync.asData?.value ?? [];
    }

    final bannerImage = item.imageUrl ?? '';

    final title = item.title ?? item.product?.name ?? 'Trending Collection';
    final subtitle =
        item.subtitle ?? item.product?.category?.name ?? 'Trending Now';
    final description = item.contentBody;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ─── TOP BANNER APP BAR ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.black87,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CustomNetworkImage(bannerImage, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subtitle.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null &&
                            description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── SECTION HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Produk (${products.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Pilihan Terbaik',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // ─── LIST PRODUCT GRID ───────────────────────────────────────────
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 54,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada produk di trending ini',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  final imageUrl =
                      (product.images != null && product.images!.isNotEmpty)
                      ? product.images!.first
                      : (product.imageUrl ?? '');

                  return ProductCard(
                    product: product,
                    image: imageUrl,
                    title: product.name,
                    brand: product.category?.name ?? 'Zelvira',
                    price: product.discountPrice ?? product.price,
                    originalPrice: product.discountPrice != null
                        ? product.price
                        : null,
                    rating: product.rating,
                    description:
                        product.shortDescription ?? product.description,
                  );
                }, childCount: products.length),
              ),
            ),
        ],
      ),
    );
  }
}
