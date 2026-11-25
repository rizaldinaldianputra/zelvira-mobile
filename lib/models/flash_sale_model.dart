class FlashSaleItem {
  final int? id;
  final int productId;
  final int variantId;
  final String? productName;
  final String? productImageUrl;
  final double discountPrice;
  final double originalPrice;
  final int? stockLimit;
  final int? soldCount;

  FlashSaleItem({
    this.id,
    required this.productId,
    required this.variantId,
    this.productName,
    this.productImageUrl,
    required this.discountPrice,
    required this.originalPrice,
    this.stockLimit,
    this.soldCount,
  });

  factory FlashSaleItem.fromJson(Map<String, dynamic> json) {
    return FlashSaleItem(
      id: json['id'],
      productId: json['productId'] ?? 0,
      variantId: json['variantId'] ?? 0,
      productName: json['productName'],
      productImageUrl: json['productImageUrl'],
      discountPrice: (json['discountPrice'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      stockLimit: json['stockLimit'],
      soldCount: json['soldCount'],
    );
  }
}

class FlashSale {
  final int? id;
  final String name;
  final String platform;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final List<FlashSaleItem> items;
  final String? createdAt;

  FlashSale({
    this.id,
    required this.name,
    required this.platform,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.items,
    this.createdAt,
  });

  factory FlashSale.fromJson(Map<String, dynamic> json) {
    return FlashSale(
      id: json['id'],
      name: json['name'] ?? '',
      platform: json['platform'] ?? 'ALL',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isActive: json['isActive'] ?? false,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => FlashSaleItem.fromJson(i)).toList()
          : [],
      createdAt: json['createdAt'],
    );
  }
}
