class NewsModel {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String? author;
  final String? imageUrl;
  final String status;
  final String? createdAt;
  final String? targetUserId;

  NewsModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.author,
    this.imageUrl,
    required this.status,
    this.createdAt,
    this.targetUserId,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? 'Zelvira Editor',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'ZELVIRA NEWS',
      createdAt: json['createdAt'],
      targetUserId: json['targetUserId'] != null ? 'Personal' : 'Public',
    );
  }
}
