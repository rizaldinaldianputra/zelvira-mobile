import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/custom_network_image.dart';
import '../../models/content_section_model.dart';
import '../../riverpod/home_provider.dart';

class TrendingPage extends ConsumerStatefulWidget {
  const TrendingPage({super.key});

  @override
  ConsumerState<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends ConsumerState<TrendingPage> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(homeTrendingContentProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Semua Trending',
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
        actions: [
          IconButton(
            icon: Icon(
              _isGrid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              color: Colors.black87,
            ),
            tooltip: _isGrid ? 'Tampilan List' : 'Tampilan Grid',
            onPressed: () {
              setState(() {
                _isGrid = !_isGrid;
              });
            },
          ),
        ],
      ),
      body: trendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada konten trending yang tersedia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              try {
                // ignore: unused_result
                await ref.refresh(homeTrendingContentProvider.future);
              } catch (_) {}
            },
            child: _isGrid
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildTrendingGridCard(context, item, index);
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildTrendingListCard(context, item, index);
                    },
                  ),
          );
        },
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text('Gagal memuat trending: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(homeTrendingContentProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingGridCard(
    BuildContext context,
    ContentItem item,
    int index,
  ) {
    final product = item.product;
    final imageUrl = item.imageUrl ?? '';
    final title = item.title ?? product?.name ?? 'Trending Collection';
    final subtitle = item.subtitle ?? product?.category?.name ?? 'Collection';
    final productCount =
        item.products?.length ?? (item.product != null ? 1 : 0);

    return GestureDetector(
      onTap: () {
        context.push('/trending-detail', extra: item);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CustomNetworkImage(imageUrl, fit: BoxFit.cover),
              // Dark gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (productCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$productCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Bottom title & cta
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Lihat Detail',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white70,
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingListCard(
    BuildContext context,
    ContentItem item,
    int index,
  ) {
    final product = item.product;
    final imageUrl = item.imageUrl ?? '';
    final title = item.title ?? product?.name ?? 'Trending Collection';
    final subtitle = item.subtitle ?? product?.category?.name ?? 'Collection';
    final productCount =
        item.products?.length ?? (item.product != null ? 1 : 0);

    return GestureDetector(
      onTap: () {
        context.push('/trending-detail', extra: item);
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomNetworkImage(imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (productCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$productCount Produk',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Bottom Title and Action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.contentBody != null &&
                                  item.contentBody!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.contentBody!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
