import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../riverpod/home_provider.dart';
import '../../components/custom_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../components/error_retry_widget.dart';

class HomeTrendingList extends ConsumerWidget {
  const HomeTrendingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(homeTrendingContentProvider);

    return trendingAsync.when(
      data: (items) {
        // Show shimmer placeholders if no content configured
        if (items.isEmpty) {
          return _buildShimmerList();
        }

        // Show at most 5 items on the home screen
        final displayItems = items.take(5).toList();

        return SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final product = item.product;

              final imageUrl = item.imageUrl;
              final title = item.title ?? product?.name ?? 'Trending Selection';
              final subtitle =
                  item.subtitle ?? product?.category?.name ?? 'Collection';

              return GestureDetector(
                onTap: () {
                  context.push('/trending-detail', extra: item);
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
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
                        CustomNetworkImage(imageUrl ?? '', fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Skeletonizer(enabled: true, child: _buildShimmerList()),
      error: (error, _) => ErrorRetryWidget(
        height: 200,
        onRetry: () => ref.refresh(homeTrendingContentProvider),
      ),
    );
  }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.65),
            highlightColor: Colors.white,
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
