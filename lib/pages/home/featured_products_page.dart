import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/card_widget.dart';
import '../../riverpod/home_provider.dart';
import '../../models/product_model.dart';

class FeaturedProductsPage extends ConsumerStatefulWidget {
  const FeaturedProductsPage({super.key});

  @override
  ConsumerState<FeaturedProductsPage> createState() =>
      _FeaturedProductsPageState();
}

class _FeaturedProductsPageState extends ConsumerState<FeaturedProductsPage> {
  String _selectedSort = 'Populer';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(homeFeaturedProductsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Featured Products',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ─── SEARCH & FILTER BAR ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari produk featured...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'Populer',
                          'Terbaru',
                          'Harga Terendah',
                          'Harga Tertinggi',
                        ].map((sort) {
                          final isSelected = _selectedSort == sort;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSort = sort),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                sort,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ─── PRODUCT GRID ──────────────────────────────────────────────────
          Expanded(
            child: featuredAsync.when(
              data: (products) {
                var list = List<Product>.from(products);

                if (_searchQuery.isNotEmpty) {
                  list = list
                      .where((p) => p.name.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (_selectedSort == 'Harga Terendah') {
                  list.sort(
                    (a, b) => (a.discountPrice ?? a.price).compareTo(
                      b.discountPrice ?? b.price,
                    ),
                  );
                } else if (_selectedSort == 'Harga Tertinggi') {
                  list.sort(
                    (a, b) => (b.discountPrice ?? b.price).compareTo(
                      a.discountPrice ?? a.price,
                    ),
                  );
                } else if (_selectedSort == 'Terbaru') {
                  list.sort((a, b) => b.id.compareTo(a.id));
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada produk yang cocok',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    try {
                      // ignore: unused_result
                      await ref.refresh(homeFeaturedProductsProvider.future);
                    } catch (_) {}
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.58,
                        ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final product = list[index];
                      final imageUrl =
                          (product.images != null && product.images!.isNotEmpty)
                          ? product.images!.first
                          : (product.imageUrl ?? '');

                      final hasDiscount =
                          product.discountPrice != null &&
                          product.discountPrice! > 0;
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
                        brand: product.category?.name ?? 'Zelvira',
                        price: displayPrice,
                        originalPrice: displayOriginalPrice,
                        rating: product.rating,
                        description:
                            product.shortDescription ?? product.description,
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
                    },
                  ),
                );
              },
              loading: () => Skeletonizer(
                enabled: true,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 14, width: double.infinity, color: Colors.white),
                              const SizedBox(height: 8),
                              Container(height: 12, width: 80, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Gagal memuat produk: $err'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(homeFeaturedProductsProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
