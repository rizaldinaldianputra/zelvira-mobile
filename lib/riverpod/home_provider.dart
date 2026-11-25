import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_section_model.dart';
import '../services/content_service.dart';
import '../services/category_service.dart';
import '../models/category_model.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import '../services/flash_sale_service.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../services/digital_product_service.dart';

final digitalServiceProvider = Provider<DigitalProductService>((ref) {
  return DigitalProductService();
});

final digitalActiveCategoriesProvider = FutureProvider<List<DigitalCategoryItem>>((ref) async {
  final service = ref.read(digitalServiceProvider);
  return service.getCategoriesList(onlyActive: true);
});

final digitalConfigProvider = FutureProvider<DigitalProductConfig>((ref) async {
  final service = ref.read(digitalServiceProvider);
  return service.getConfig();
});

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService();
});

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService();
});

final flashSaleServiceProvider = Provider<FlashSaleService>((ref) {
  return FlashSaleService();
});

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

// Sections Provider (Grouped Content)
final homeSectionsProvider = FutureProvider<List<ContentSection>>((ref) async {
  final service = ref.read(contentServiceProvider);
  try {
    final sections = await service.getSections();
    if (sections.isNotEmpty) return sections;
    
    // Fallback default sections if none are configured in database for MOBILE
    return [
      ContentSection(
        type: 'MOBILE_PROMO',
        platform: 'MOBILE',
        displayOrder: 0,
        isActive: true,
        items: [],
        title: 'Promo Spesial',
      ),
      ContentSection(
        type: 'CATEGORY_ICONS',
        platform: 'MOBILE',
        displayOrder: 1,
        isActive: true,
        items: [],
        title: 'Categories',
      ),
      ContentSection(
        type: 'FLASH_SALE_MOBILE',
        platform: 'MOBILE',
        displayOrder: 2,
        isActive: true,
        items: [],
        title: 'Flash Sale',
      ),
      ContentSection(
        type: 'TRENDING_LIST',
        platform: 'MOBILE',
        displayOrder: 3,
        isActive: true,
        items: [],
        title: 'Trending Now',
      ),
      ContentSection(
        type: 'NEWS',
        platform: 'MOBILE',
        displayOrder: 4,
        isActive: true,
        items: [],
        title: 'News & Updates',
      ),
      ContentSection(
        type: 'FEATURED_MOBILE',
        platform: 'MOBILE',
        displayOrder: 5,
        isActive: true,
        items: [],
        title: 'Featured Products',
      ),
    ];
  } catch (e) {
    // Return defaults on error to keep UI alive
    return [
       ContentSection(type: 'MOBILE_PROMO', platform: 'MOBILE', displayOrder: 0, isActive: true, items: []),
       ContentSection(type: 'FLASH_SALE_MOBILE', platform: 'MOBILE', displayOrder: 1, isActive: true, items: []),
       ContentSection(type: 'TRENDING_LIST', platform: 'MOBILE', displayOrder: 2, isActive: true, items: []),
       ContentSection(type: 'FEATURED_MOBILE', platform: 'MOBILE', displayOrder: 4, isActive: true, items: []),
    ];
  }
});

// Promo Banners Provider — fetches MOBILE_PROMO or PROMO
final homePromoBannersProvider = FutureProvider<List<ContentItem>>((ref) async {
  final service = ref.read(contentServiceProvider);
  try {
    final items = await service.getItemsByType('MOBILE_PROMO');
    if (items.isNotEmpty) return items;
    return await service.getItemsByType('PROMO');
  } catch (e) {
    return await service.getItemsByType('PROMO');
  }
});

// Featured Products Content Provider — supports both WEB and MOBILE type names (Legacy)
final homeFeaturedContentProvider = FutureProvider<List<ContentItem>>((ref) async {
  final service = ref.read(contentServiceProvider);
  final items = await service.getItemsByType('FEATURED_MOBILE');
  if (items.isNotEmpty) return items;
  return await service.getItemsByType('FEATURED_PRODUCTS');
});

// Featured Products Provider — fetched directly from master products (/api/v1/products/featured)
final homeFeaturedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.read(productServiceProvider);
  return await service.getFeaturedProducts();
});

// Flash Sale Content Provider — fetches active campaigns and maps them to ContentItems
final homeFlashSaleContentProvider = FutureProvider<List<ContentItem>>((ref) async {
  final flashSaleService = ref.read(flashSaleServiceProvider);
  final productService = ref.read(productServiceProvider);
  
  try {
    final flashSales = await flashSaleService.getActiveFlashSales();
    if (flashSales.isEmpty) return <ContentItem>[];
    
    // Filter to active mobile flash sales
    final mobileSales = flashSales.where((fs) => fs.isActive && fs.platform == 'MOBILE').toList();
    if (mobileSales.isEmpty) return <ContentItem>[];
    
    // Gather all product IDs
    final List<int> productIds = [];
    for (var fs in mobileSales) {
      for (var item in fs.items) {
        if (!productIds.contains(item.productId)) {
          productIds.add(item.productId);
        }
      }
    }
    
    if (productIds.isEmpty) return <ContentItem>[];
    
    // Fetch products in one batch
    final products = await productService.getProductsByIds(productIds);
    final Map<int, Product> productMap = {for (var p in products) p.id: p};
    
    final List<ContentItem> contentItems = [];
    for (var fs in mobileSales) {
      for (var item in fs.items) {
        final normalProduct = productMap[item.productId];
        if (normalProduct == null) continue;
        
        // Clone variants and override price with flash sale discountPrice
        final updatedVariants = normalProduct.variants.map((v) {
          if (v.id == item.variantId) {
            return ProductVariant(
              id: v.id,
              sku: v.sku,
              size: v.size,
              color: v.color,
              hexColor: v.hexColor,
              groupName: v.groupName,
              price: item.discountPrice, // Flash sale price
              discountPrice: item.originalPrice, // Original/retail price as discountPrice helper
              costPrice: v.costPrice,
              barcode: v.barcode,
              stock: item.stockLimit ?? v.stock,
              isActive: v.isActive,
              imageUrl: v.imageUrl,
            );
          }
          return v;
        }).toList();
        
        final flashProduct = Product(
          id: normalProduct.id,
          name: normalProduct.name,
          slug: normalProduct.slug,
          description: normalProduct.description,
          imageUrl: item.productImageUrl ?? normalProduct.imageUrl,
          shortDescription: normalProduct.shortDescription,
          categoryId: normalProduct.categoryId,
          brandId: normalProduct.brandId,
          gender: normalProduct.gender,
          material: normalProduct.material,
          weight: normalProduct.weight,
          isActive: normalProduct.isActive,
          isFeatured: normalProduct.isFeatured,
          isTopProduct: normalProduct.isTopProduct,
          isBestSeller: normalProduct.isBestSeller,
          isRecommended: normalProduct.isRecommended,
          category: normalProduct.category,
          variants: updatedVariants,
          images: normalProduct.images,
        );
        
        contentItems.add(
          ContentItem(
            id: item.id,
            platform: 'MOBILE',
            type: 'FLASH_SALE',
            title: fs.name,
            imageUrl: item.productImageUrl,
            startDate: fs.startTime,
            endDate: fs.endTime,
            product: flashProduct,
          ),
        );
      }
    }
    
    return contentItems;
  } catch (_) {
    return <ContentItem>[];
  }
});

// Trending Now Content Provider — supports TRENDING_NOW and TRENDING_LIST
final homeTrendingContentProvider = FutureProvider<List<ContentItem>>((ref) async {
  final service = ref.read(contentServiceProvider);
  try {
    final items = await service.getItemsByType('TRENDING_LIST');
    if (items.isNotEmpty) return items;
    return await service.getItemsByType('TRENDING_NOW');
  } catch (e) {
    return await service.getItemsByType('TRENDING_NOW');
  }
});

// News Content Provider (Using dedicated NewsService)
final homeNewsContentProvider = FutureProvider<List<NewsModel>>((ref) async {
  final service = ref.read(newsServiceProvider);
  return service.getAllNews();
});

// Home Categories Provider
final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.read(categoryServiceProvider);
  return service.getCategories();
});
