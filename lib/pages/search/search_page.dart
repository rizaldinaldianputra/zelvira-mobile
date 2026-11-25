import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/card_widget.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../config/url_utils.dart';
import '../../config/app_style.dart';

class SearchPage extends StatefulWidget {
  final int? selectedCategoryId;
  const SearchPage({super.key, this.selectedCategoryId});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<String> searchHistory = [];
  bool isSearching = false;
  bool isLoading = false;
  bool isLoadingCategories = true;
  List<Product> searchResults = [];
  List<Category> categories = [];
  int? currentCategoryId;

  @override
  void initState() {
    super.initState();
    currentCategoryId = widget.selectedCategoryId;
    _loadSearchHistory();
    _fetchCategories();
    if (currentCategoryId != null) {
      _onSearch('');
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('search_history') ?? [];
      if (mounted) {
        setState(() {
          searchHistory = saved;
        });
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(searchHistory);
      list.remove(trimmed);
      list.insert(0, trimmed);
      if (list.length > 10) {
        list.removeRange(10, list.length);
      }
      await prefs.setStringList('search_history', list);
      if (mounted) {
        setState(() {
          searchHistory = list;
        });
      }
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _removeSearchHistoryItem(String item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(searchHistory);
      list.remove(item);
      await prefs.setStringList('search_history', list);
      if (mounted) {
        setState(() {
          searchHistory = list;
        });
      }
    } catch (e) {
      debugPrint('Error removing search history item: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      if (mounted) {
        setState(() {
          searchHistory.clear();
        });
      }
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final fetchedCategories = await _categoryService.getCategories(size: 15);
      if (mounted) {
        setState(() {
          categories = fetchedCategories;
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) setState(() => isLoadingCategories = false);
    }
  }

  void _onSearch(String query) async {
    final trimmed = query.trim();

    if (trimmed.isNotEmpty) {
      _saveSearchQuery(trimmed);
    }

    if (trimmed.isEmpty && currentCategoryId == null) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
      isLoading = true;
    });

    try {
      final results = await _productService.searchProducts(
        query: trimmed,
        categoryId: currentCategoryId,
      );

      if (mounted) {
        setState(() {
          searchResults = results;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint('Search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearch,
            autofocus: currentCategoryId == null,
            decoration: InputDecoration(
              hintText: 'Cari produk impianmu...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              icon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (isSearching ? _buildResults() : _buildHistory()),
    );
  }

  Widget _buildHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pencarian Terakhir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searchHistory
                  .map((query) => _buildHistoryChip(query))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],
          const Text(
            'Kategori Populer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (isLoadingCategories)
            _buildCategoriesSkeletonGrid()
          else if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Tidak ada kategori tersedia',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                return _buildPopularCategory(categories[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _searchController.text = label;
              _onSearch(label);
            },
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSearchHistoryItem(label),
            child: const Icon(Icons.close, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSkeletonGrid() {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularCategory(Category category) {
    final isSelected = currentCategoryId == category.id;
    final formattedImg = UrlUtils.formatImageUrl(category.imageUrl);

    return InkWell(
      onTap: () {
        setState(() {
          currentCategoryId = isSelected ? null : category.id;
          _searchController.clear();
        });
        _onSearch('');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: formattedImg.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomNetworkImage(
                        formattedImg,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      size: 24,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/empty.json', width: 250, height: 250),
            const SizedBox(height: 16),
            const Text(
              'Produk tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba gunakan kata kunci lain atau hapus filter',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        final hasDiscount =
            product.discountPrice != null && product.discountPrice! > 0;
        final double displayPrice = hasDiscount
            ? product.discountPrice!
            : product.price;
        final double? displayOriginalPrice = hasDiscount ? product.price : null;

        return ProductCard(
          product: product,
          image:
              product.imageUrl ??
              (product.images?.isNotEmpty == true ? product.images!.first : ''),
          title: product.name,
          brand: 'Zelvira',
          price: displayPrice,
          originalPrice: displayOriginalPrice,
          rating: product.rating,
        );
      },
    );
  }
}
