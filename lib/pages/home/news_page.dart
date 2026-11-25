import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_style.dart';
import '../../riverpod/news_provider.dart';

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  Future<void> _handleRefresh() async {
    await ref.read(newsProvider.notifier).fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Zelvira News',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: newsState.when(
        data: (newsList) {
          if (newsList.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Belum ada berita")),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return GestureDetector(
                  onTap: () => context.push('/news-detail', extra: news),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: CustomNetworkImage(
                            news.imageUrl ?? '',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      news.status,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    news.createdAt ?? 'Terbaru',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                news.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                news.content.replaceAll(
                                  RegExp(r'<[^>]*>|&[^;]+;'),
                                  ' ',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        error: (err, st) => RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: ListView(
            children: [
              const SizedBox(height: 200),
              Center(child: Text("Error: $err")),
            ],
          ),
        ),
      ),
    );
  }
}
