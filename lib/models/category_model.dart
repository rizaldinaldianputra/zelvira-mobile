class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int pointsReward;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.pointsReward = 0,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      pointsReward: json['pointsReward'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}
