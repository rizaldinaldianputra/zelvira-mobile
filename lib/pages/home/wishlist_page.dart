import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_style.dart';
import '../../components/card_widget.dart';
import '../../riverpod/wishlist_provider.dart';
import '../../services/wishlist_service.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final items = wishlistState.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wishlist Saya',
              style: AppStyle.heading.copyWith(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            if (items.isNotEmpty)
              Text(
                '${items.length} produk tersimpan',
                style: AppStyle.bodyText.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
      body: wishlistState.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(wishlistProvider.notifier).loadWishlist(),
              child: items.isEmpty
                  ? _buildEmptyState(context)
                  : _buildWishlistGrid(items),
            ),
    );
  }

  Widget _buildWishlistGrid(List<WishlistItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final product = item.product;
        final imageUrl = (product.images != null && product.images!.isNotEmpty)
            ? product.images!.first
            : (product.imageUrl ?? '');

        return ProductCard(
          product: product,
          image: imageUrl,
          title: product.name,
          brand: product.category?.name ?? 'Zelvira',
          price: product.discountPrice ?? product.price,
          originalPrice: product.discountPrice != null ? product.price : null,
          rating: product.rating,
          isFavorite: true,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 50,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Wishlist Masih Kosong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simpan produk favorit Anda di sini dengan mengetuk ikon hati pada produk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
