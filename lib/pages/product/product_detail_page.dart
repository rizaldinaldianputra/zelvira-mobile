import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_style.dart';
import '../../models/product_model.dart';
import '../../riverpod/cart_provider.dart';
import '../../config/url_utils.dart';
import '../../riverpod/wishlist_provider.dart';
import '../../components/notifcation_widget.dart';
import '../../services/review_service.dart';
import '../../services/product_service.dart';
import '../../config/currency_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'product_reviews_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Product? product;
  final String title;
  final String brand;
  final List<String> images;
  final double price;
  final double? originalPrice;
  final double rating;
  final String? description;
  final List<String>? sizes;
  final List<String>? colorHexes;
  final int stock;
  final int soldCount;

  const ProductDetailPage({
    super.key,
    this.product,
    required this.images,
    required this.title,
    required this.brand,
    required this.price,
    this.originalPrice,
    this.rating = 0.0,
    this.description,
    this.sizes,
    this.colorHexes,
    this.stock = 100,
    this.soldCount = 45,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  Product? _currentProduct;
  Product? get _product => _currentProduct ?? widget.product;

  String? selectedGroupName;
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;
  int activeImageIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _realReviews = [];
  bool _isLoadingReviews = false;

  double get effectiveRating {
    if (_realReviews.isNotEmpty) {
      final sum = _realReviews.fold<double>(0.0, (prev, r) {
        final rVal = (r['rating'] is num)
            ? (r['rating'] as num).toDouble()
            : 0.0;
        return prev + rVal;
      });
      return sum / _realReviews.length;
    }
    if (_product?.averageRating != null && _product!.averageRating! > 0) {
      return _product!.averageRating!;
    }
    return widget.rating > 0 ? widget.rating : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _initializeSelections();
    _loadProductReviews();
  }

  Future<void> _refreshProductDetail() async {
    final productId = _product?.id;
    if (productId != null) {
      try {
        final freshProduct = await ProductService().getProductById(productId);
        if (freshProduct != null && mounted) {
          setState(() {
            _currentProduct = freshProduct;
            _initializeSelections();
          });
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await _loadProductReviews();
  }

  Future<void> _loadProductReviews() async {
    final productId = _product?.id;
    if (productId == null || !mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ReviewService().getProductReviews(
        productId,
        size: 5,
      );
      if (mounted) {
        setState(() {
          _realReviews = reviews;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  void _initializeSelections() {
    final prod = _product;
    if (prod != null && prod.variants.isNotEmpty) {
      final firstVariant = prod.variants.first;
      selectedGroupName =
          (firstVariant.groupName != null &&
              firstVariant.groupName!.trim().isNotEmpty)
          ? firstVariant.groupName!.trim()
          : ((firstVariant.color != null &&
                    firstVariant.color!.trim().isNotEmpty)
                ? firstVariant.color!.trim()
                : 'Standar');
      selectedSize = firstVariant.size;
      selectedColor = firstVariant.color ?? firstVariant.hexColor;
    } else {
      selectedGroupName = 'Standar';
      selectedSize = (widget.sizes != null && widget.sizes!.isNotEmpty)
          ? widget.sizes![0]
          : 'M';
      selectedColor =
          (widget.colorHexes != null && widget.colorHexes!.isNotEmpty)
          ? widget.colorHexes![0]
          : '#FF5733';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      String hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _resolveColor(String? colorName, String? hex) {
    if (hex != null && hex.trim().isNotEmpty) {
      return _hexToColor(hex);
    }
    if (colorName != null && colorName.trim().isNotEmpty) {
      final cLower = colorName.trim().toLowerCase();
      switch (cLower) {
        case 'hitam':
        case 'black':
          return const Color(0xFF1E1E1E);
        case 'putih':
        case 'white':
          return const Color(0xFFF5F5F5);
        case 'merah':
        case 'red':
          return const Color(0xFFE53935);
        case 'biru':
        case 'blue':
          return const Color(0xFF1E88E5);
        case 'navy':
        case 'biru dongker':
          return const Color(0xFF0D253F);
        case 'hijau':
        case 'green':
          return const Color(0xFF43A047);
        case 'kuning':
        case 'yellow':
          return const Color(0xFFFDD835);
        case 'abu-abu':
        case 'abu':
        case 'grey':
        case 'gray':
          return const Color(0xFF9E9E9E);
        case 'cokelat':
        case 'coklat':
        case 'brown':
          return const Color(0xFF795548);
        case 'pink':
        case 'merah muda':
          return const Color(0xFFEC407A);
        case 'ungu':
        case 'purple':
          return const Color(0xFF8E24AA);
        case 'orange':
        case 'oranye':
        case 'jingga':
          return const Color(0xFFFB8C00);
        case 'krem':
        case 'cream':
        case 'beige':
          return const Color(0xFFF5F5DC);
        case 'maroon':
        case 'marun':
          return const Color(0xFF800000);
      }
    }
    return Colors.grey.shade400;
  }

  ProductVariant? _getSelectedVariant() {
    final prod = _product;
    if (prod == null || prod.variants.isEmpty) return null;
    try {
      return prod.variants.firstWhere(
        (v) {
          final gName = (v.groupName != null && v.groupName!.trim().isNotEmpty)
              ? v.groupName!.trim()
              : ((v.color != null && v.color!.trim().isNotEmpty)
                    ? v.color!.trim()
                    : 'Standar');
          final matchesGroup =
              selectedGroupName == null || gName == selectedGroupName;
          final matchesSize = selectedSize == null || v.size == selectedSize;
          final matchesColor =
              selectedColor == null ||
              v.color == selectedColor ||
              v.hexColor == selectedColor;
          return matchesGroup && matchesSize && matchesColor;
        },
        orElse: () => prod.variants.firstWhere(
          (v) {
            final gName =
                (v.groupName != null && v.groupName!.trim().isNotEmpty)
                ? v.groupName!.trim()
                : ((v.color != null && v.color!.trim().isNotEmpty)
                      ? v.color!.trim()
                      : 'Standar');
            final matchesGroup =
                selectedGroupName == null || gName == selectedGroupName;
            final matchesColor =
                selectedColor == null ||
                v.color == selectedColor ||
                v.hexColor == selectedColor;
            return matchesGroup && matchesColor;
          },
          orElse: () => prod.variants.firstWhere((v) {
            final gName =
                (v.groupName != null && v.groupName!.trim().isNotEmpty)
                ? v.groupName!.trim()
                : ((v.color != null && v.color!.trim().isNotEmpty)
                      ? v.color!.trim()
                      : 'Standar');
            return selectedGroupName == null || gName == selectedGroupName;
          }, orElse: () => prod.variants.first),
        ),
      );
    } catch (e) {
      return prod.variants.first;
    }
  }

  Future<void> _addToCart() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Silakan Login'),
          description: const Text(
            'Anda harus login untuk menambahkan ke keranjang.',
          ),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 2),
        );
        context.push('/login');
      }
      return;
    }

    final variant = _getSelectedVariant();
    if (variant == null) {
      toastification.show(
        context: context,
        title: const Text('Gagal menambahkan ke keranjang'),
        description: const Text('Data produk tidak valid'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    if (variant.stock <= 0) {
      toastification.show(
        context: context,
        title: const Text('Stok Habis'),
        description: const Text('Maaf, produk ini sedang habis'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    if (quantity > variant.stock) {
      toastification.show(
        context: context,
        title: const Text('Jumlah Melebihi Stok'),
        description: Text('Stok hanya tersedia ${variant.stock}'),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      await ref.read(cartProvider.notifier).addToCart(variant.id, quantity);
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Berhasil!'),
          description: Text('${widget.title} ditambahkan ke keranjang'),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('401') ||
            errorStr.toLowerCase().contains('unauthorized')) {
          toastification.show(
            context: context,
            title: const Text('Silakan Login'),
            description: const Text(
              'Sesi login telah berakhir. Silakan login kembali.',
            ),
            type: ToastificationType.warning,
            autoCloseDuration: const Duration(seconds: 2),
          );
          context.push('/login');
        } else {
          toastification.show(
            context: context,
            title: const Text('Gagal'),
            description: Text(errorStr.replaceAll('Exception: ', '')),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  void _buyNow() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Silakan Login'),
          description: const Text(
            'Anda harus login terlebih dahulu untuk checkout.',
          ),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 2),
        );
        context.push('/login');
      }
      return;
    }

    final variant = _getSelectedVariant();
    if (variant == null) return;

    if (variant.stock <= 0) {
      toastification.show(
        context: context,
        title: const Text('Stok Habis'),
        description: const Text('Maaf, varian produk ini sedang habis'),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    if (quantity > variant.stock) {
      toastification.show(
        context: context,
        title: const Text('Jumlah Melebihi Stok'),
        description: Text('Stok hanya tersedia ${variant.stock}'),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    context.push(
      '/checkout',
      extra: {
        'productId': widget.product?.id ?? 0,
        'variantId': variant.id,
        'title': widget.title,
        'price': widget.price,
        'image':
            variant.imageUrl ??
            (widget.images.isNotEmpty ? widget.images[0] : ''),
        'quantity': quantity,
        'size': selectedSize,
        'color': selectedColor,
        'brand': widget.brand,
        'stock': variant.stock,
      },
    );
  }

  void _showVariantBottomSheet({bool isBuyNow = false}) {
    final prod = _product;
    if (prod == null || prod.variants.isEmpty) return;

    final qtyController = TextEditingController(text: quantity.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // 1. Group variants by groupName, or color, or fallback to 'Standar'
            final Map<String, List<ProductVariant>> groupedVariants = {};
            for (final v in prod.variants) {
              final gName =
                  (v.groupName != null && v.groupName!.trim().isNotEmpty)
                  ? v.groupName!.trim()
                  : ((v.color != null && v.color!.trim().isNotEmpty)
                        ? v.color!.trim()
                        : 'Standar');
              groupedVariants.putIfAbsent(gName, () => []).add(v);
            }

            // 2. Default to the FIRST variant group if not already set or invalid
            if (selectedGroupName == null ||
                !groupedVariants.containsKey(selectedGroupName)) {
              selectedGroupName = groupedVariants.keys.first;
            }

            // Variants in currently active group
            final currentGroupVariants =
                groupedVariants[selectedGroupName] ?? [];

            // Available colors in current group
            final List<String> groupColors = currentGroupVariants
                .map((v) => v.color?.trim() ?? '')
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();

            final List<String> availableColors = groupColors.isNotEmpty
                ? groupColors
                : (selectedGroupName != null && selectedGroupName != 'Standar'
                      ? [selectedGroupName!]
                      : (widget.colorHexes ?? []));

            if (selectedColor == null ||
                (availableColors.isNotEmpty &&
                    !availableColors.contains(selectedColor))) {
              if (availableColors.isNotEmpty) {
                selectedColor = availableColors.first;
              }
            }

            // Available sizes for currently selected color (or all sizes in group)
            final List<String> sizesForColor = currentGroupVariants
                .where(
                  (v) =>
                      selectedColor == null ||
                      v.color == selectedColor ||
                      v.hexColor == selectedColor,
                )
                .map((v) => v.size?.trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();

            final List<String> groupSizes = sizesForColor.isNotEmpty
                ? sizesForColor
                : currentGroupVariants
                      .map((v) => v.size?.trim() ?? '')
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList();

            // If selectedSize is not set or not in this group, default to first ready size
            if (selectedSize == null || !groupSizes.contains(selectedSize)) {
              final readyInGroup = currentGroupVariants.firstWhere(
                (v) =>
                    (v.stock > 0) &&
                    (selectedColor == null ||
                        v.color == selectedColor ||
                        v.hexColor == selectedColor),
                orElse: () => currentGroupVariants.firstWhere(
                  (v) =>
                      (selectedColor == null ||
                      v.color == selectedColor ||
                      v.hexColor == selectedColor),
                  orElse: () => currentGroupVariants.isNotEmpty
                      ? currentGroupVariants.first
                      : prod.variants.first,
                ),
              );
              selectedSize = readyInGroup.size;
              selectedColor ??= readyInGroup.color ?? readyInGroup.hexColor;
            }

            // Find current selected variant
            final selectedVariant = currentGroupVariants.firstWhere(
              (v) =>
                  (v.size == selectedSize || selectedSize == null) &&
                  (v.color == selectedColor ||
                      v.hexColor == selectedColor ||
                      selectedColor == null),
              orElse: () => currentGroupVariants.isNotEmpty
                  ? currentGroupVariants.first
                  : prod.variants.first,
            );

            // Group thumbnail image: variant image or group first image or product image
            final groupVariantWithImg = currentGroupVariants.firstWhere(
              (v) => v.imageUrl != null && v.imageUrl!.isNotEmpty,
              orElse: () => currentGroupVariants.isNotEmpty
                  ? currentGroupVariants.first
                  : prod.variants.first,
            );
            final String activeDisplayImage =
                selectedVariant.imageUrl ??
                groupVariantWithImg.imageUrl ??
                (widget.images.isNotEmpty ? widget.images[0] : '');

            final int availableStock = selectedVariant.stock;
            final bool isOutOfStock = availableStock <= 0;

            // Quantity adjustment
            if (isOutOfStock && quantity != 0) {
              quantity = 0;
              qtyController.text = '0';
            } else if (!isOutOfStock &&
                (quantity > availableStock || quantity <= 0)) {
              quantity = (availableStock > 0) ? 1 : 0;
              qtyController.text = quantity.toString();
            }

            // Gating button: must have selected variant group, selected variant, stock > 0, and qty > 0
            final bool isGroupChosen =
                selectedGroupName != null &&
                groupedVariants.containsKey(selectedGroupName);
            final bool canProceed =
                isGroupChosen && !isOutOfStock && quantity > 0;

            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: IMAGE & PRICE & STOCK ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          image: DecorationImage(
                            image: NetworkImage(
                              UrlUtils.formatImageUrl(activeDisplayImage),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              CurrencyUtils.format(
                                selectedVariant.discountPrice ??
                                    selectedVariant.price,
                              ),
                              style: AppStyle.priceText.copyWith(
                                fontSize: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOutOfStock
                                      ? 'Stok Habis'
                                      : 'Stok: $availableStock tersedia',
                                  style: TextStyle(
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pilihan: $selectedGroupName${selectedColor != null ? ' • $selectedColor' : ''}${selectedSize != null ? ' • $selectedSize' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // --- SCROLLABLE BODY ---
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. VARIANT GROUPING WITH IMAGES
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pilihan Varian',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${groupedVariants.length} varian',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: groupedVariants.keys.map((gName) {
                              final isSelected = selectedGroupName == gName;
                              final gVariants = groupedVariants[gName] ?? [];
                              final gImg = gVariants
                                  .firstWhere(
                                    (v) =>
                                        v.imageUrl != null &&
                                        v.imageUrl!.isNotEmpty,
                                    orElse: () => gVariants.first,
                                  )
                                  .imageUrl;
                              final int totalGroupStock = gVariants.fold(
                                0,
                                (sum, v) => sum + v.stock,
                              );
                              final bool isGroupEmpty = totalGroupStock <= 0;

                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedGroupName = gName;
                                    // Automatically switch to first ready size in this new group
                                    final ready = gVariants.firstWhere(
                                      (v) => v.stock > 0,
                                      orElse: () => gVariants.first,
                                    );
                                    selectedSize = ready.size;
                                    selectedColor =
                                        ready.color ?? ready.hexColor;
                                    if (ready.stock > 0) {
                                      quantity = 1;
                                      qtyController.text = '1';
                                    }
                                  });
                                  if (mounted) {
                                    setState(() {
                                      selectedGroupName = gName;
                                      selectedSize = selectedSize;
                                      selectedColor = selectedColor;
                                      // Move main slider image
                                      if (gImg != null && gImg.isNotEmpty) {
                                        final idx = widget.images.indexOf(gImg);
                                        if (idx != -1 &&
                                            _pageController.hasClients) {
                                          _pageController.animateToPage(
                                            idx,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                          activeImageIndex = idx;
                                        }
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.08,
                                          )
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (gImg != null && gImg.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            UrlUtils.formatImageUrl(gImg),
                                            width: 38,
                                            height: 38,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            gName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 13,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            isGroupEmpty
                                                ? 'Habis'
                                                : '$totalGroupStock ready',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isGroupEmpty
                                                  ? Colors.red
                                                  : Colors.grey.shade500,
                                              fontWeight: isGroupEmpty
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 2. PILIHAN WARNA DENGAN COLOR CIRCLE ICON
                          if (availableColors.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pilihan Warna',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (selectedColor != null)
                                  Text(
                                    selectedColor!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 14,
                              children: availableColors.map((color) {
                                final isSelected = selectedColor == color;
                                final variantWithColor = currentGroupVariants
                                    .firstWhere(
                                      (v) =>
                                          (v.color == color ||
                                          v.hexColor == color),
                                      orElse: () => currentGroupVariants.first,
                                    );
                                final hex = variantWithColor.hexColor;
                                final circleColor = _resolveColor(color, hex);

                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedColor = color;
                                      // Check if current selectedSize exists for this color
                                      final hasMatchingSize =
                                          currentGroupVariants.any(
                                            (v) =>
                                                (v.color == color ||
                                                    v.hexColor == color) &&
                                                v.size == selectedSize,
                                          );
                                      if (!hasMatchingSize) {
                                        final readyForColor =
                                            currentGroupVariants.firstWhere(
                                              (v) =>
                                                  (v.color == color ||
                                                      v.hexColor == color) &&
                                                  v.stock > 0,
                                              orElse: () => currentGroupVariants
                                                  .firstWhere(
                                                    (v) =>
                                                        (v.color == color ||
                                                        v.hexColor == color),
                                                    orElse: () =>
                                                        currentGroupVariants
                                                            .first,
                                                  ),
                                            );
                                        selectedSize = readyForColor.size;
                                      }
                                    });
                                    if (mounted) {
                                      setState(() {
                                        selectedColor = color;
                                        selectedSize = selectedSize;
                                      });
                                    }
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: circleColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                            width: isSelected ? 3 : 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check,
                                                color:
                                                    (circleColor
                                                            .computeLuminance() >
                                                        0.5)
                                                    ? Colors.black87
                                                    : Colors.white,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        color,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 3. SIZES READY FOR THIS GROUP & COLOR
                          if (groupSizes.isNotEmpty) ...[
                            const Text(
                              'Pilih Ukuran Ready',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: groupSizes.map((size) {
                                final isSelected = selectedSize == size;
                                final variantForSize = currentGroupVariants
                                    .firstWhere(
                                      (v) =>
                                          (v.size == size) &&
                                          (selectedColor == null ||
                                              v.color == selectedColor ||
                                              v.hexColor == selectedColor),
                                      orElse: () =>
                                          currentGroupVariants.firstWhere(
                                            (v) => v.size == size,
                                            orElse: () =>
                                                currentGroupVariants.first,
                                          ),
                                    );
                                final int sizeStock = variantForSize.stock;
                                final bool isReady = sizeStock > 0;

                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedSize = size;
                                      if (isReady && quantity <= 0) {
                                        quantity = 1;
                                        qtyController.text = '1';
                                      }
                                    });
                                    if (mounted)
                                      setState(() => selectedSize = size);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isReady
                                                ? Colors.grey.shade100
                                                : Colors.grey.shade50),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      size,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : (isReady
                                                  ? Colors.black87
                                                  : Colors.grey.shade500),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 4. QUANTITY SELECTOR
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jumlah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: isOutOfStock || quantity <= 1
                                          ? null
                                          : () {
                                              setSheetState(() {
                                                quantity--;
                                                qtyController.text = quantity
                                                    .toString();
                                              });
                                            },
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: TextField(
                                        controller: qtyController,
                                        enabled: !isOutOfStock,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (val) {
                                          final newQty = int.tryParse(val);
                                          if (newQty != null) {
                                            if (newQty > availableStock) {
                                              toastification.show(
                                                context: context,
                                                title: const Text('Batas Stok'),
                                                description: Text(
                                                  'Stok hanya tersedia $availableStock',
                                                ),
                                                type:
                                                    ToastificationType.warning,
                                                autoCloseDuration:
                                                    const Duration(seconds: 2),
                                              );
                                              setSheetState(() {
                                                quantity = availableStock;
                                                qtyController.text = quantity
                                                    .toString();
                                              });
                                            } else if (newQty >= 1) {
                                              setSheetState(() {
                                                quantity = newQty;
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed:
                                          isOutOfStock ||
                                              quantity >= availableStock
                                          ? null
                                          : () {
                                              setSheetState(() {
                                                quantity++;
                                                qtyController.text = quantity
                                                    .toString();
                                              });
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 5. ACTION BUTTON (DISABLED IF NOT SELECTED / HABIS) ---
                  ElevatedButton(
                    onPressed: canProceed
                        ? () {
                            Navigator.pop(context);
                            if (isBuyNow) {
                              _buyNow();
                            } else {
                              _addToCart();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      !isGroupChosen
                          ? 'Pilih Varian Terlebih Dahulu'
                          : (isOutOfStock
                                ? 'Stok Varian Habis'
                                : (isBuyNow
                                      ? 'Beli Sekarang'
                                      : 'Masukkan Keranjang')),
                      style: TextStyle(
                        color: canProceed ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productId = _product?.id;
    final isWishlisted = productId != null
        ? ref.watch(isProductWishlistedProvider(productId))
        : false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshProductDetail,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  expandedHeight: 450,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withAlpha(200),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWishlisted
                              ? const Color(0xFFFFECEE)
                              : Colors.white.withAlpha(200),
                          border: isWishlisted
                              ? Border.all(
                                  color: Colors.red.shade300,
                                  width: 1.5,
                                )
                              : null,
                          boxShadow: isWishlisted
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted
                                ? const Color(0xFFFF1744)
                                : Colors.black,
                          ),
                          onPressed: () async {
                            if (_product != null) {
                              try {
                                final added = await ref
                                    .read(wishlistProvider.notifier)
                                    .toggleWishlist(_product!);
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
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withAlpha(200),
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.black),
                          onPressed: () {
                            final slugOrId =
                                _product?.slug ?? _product?.id.toString() ?? '';
                            final link = 'https://zelvira.id/product/$slugOrId';
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'Lihat produk keren ini: ${widget.title}\n$link',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'product-${widget.title}',
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          if (mounted) {
                            setState(() => activeImageIndex = index);
                          }
                        },
                        itemCount: widget.images.length,
                        itemBuilder: (context, index) {
                          return CustomNetworkImage(
                            UrlUtils.formatImageUrl(widget.images[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, _) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.images.length > 1)
                          Container(
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.images.length,
                              itemBuilder: (context, index) {
                                final isSelected = activeImageIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          UrlUtils.formatImageUrl(
                                            widget.images[index],
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.brand.toUpperCase(),
                                  style: AppStyle.bodyText.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.soldCount} terjual',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stok: ${widget.stock}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    effectiveRating > 0
                                        ? effectiveRating.toStringAsFixed(1)
                                        : '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          style: AppStyle.heading.copyWith(
                            fontSize: 26,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Text(
                              CurrencyUtils.format(widget.price),
                              style: AppStyle.priceText.copyWith(fontSize: 24),
                            ),
                            if (widget.originalPrice != null)
                              Text(
                                CurrencyUtils.format(widget.originalPrice),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Text('Deskripsi', style: AppStyle.subHeading),
                        const SizedBox(height: 12),
                        HtmlWidget(
                          widget.description ??
                              'Produk ini dirancang dengan kualitas premium untuk memberikan kenyamanan maksimal. Sangat cocok untuk gaya hidup modern yang mengutamakan estetika dan durabilitas.',
                          textStyle: AppStyle.bodyText.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 32),

                        Text('Spesifikasi Produk', style: AppStyle.subHeading),
                        const SizedBox(height: 12),
                        _buildSpecItem(
                          'Kategori',
                          widget.product?.category?.name ?? 'Fashion',
                        ),
                        _buildSpecItem(
                          'Material',
                          widget.product?.material ?? 'Premium Fabric',
                        ),
                        _buildSpecItem('Asal Produk', 'Lokal'),
                        _buildSpecItem(
                          'Gaya',
                          widget.product?.gender ?? 'Unisex',
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ulasan Pembeli', style: AppStyle.subHeading),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductReviewsPage(
                                      productId: widget.product?.id,
                                      productTitle: widget.title,
                                      initialRating: effectiveRating,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Lihat Semua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_realReviews.isNotEmpty)
                          ..._realReviews.take(3).map((r) {
                            final name = r['userName'] ?? 'Pelanggan';
                            final comment = r['comment'] ?? '';
                            final rating = (r['rating'] is num)
                                ? (r['rating'] as num).toDouble()
                                : 5.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildReviewItem(
                                name,
                                comment,
                                rating,
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
                              ),
                            );
                          })
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada ulasan untuk produk ini. Jadilah yang pertama memberikan review!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _showVariantBottomSheet(isBuyNow: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Keranjang',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () => _showVariantBottomSheet(isBuyNow: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Beli Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String comment,
    double rating,
    String avatar,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundImage: NetworkImage(avatar)),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 10,
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
