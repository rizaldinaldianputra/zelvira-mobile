import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_indicator/scroll_indicator.dart';
import 'package:zelvira/config/app_style.dart';
import '../../riverpod/home_provider.dart';
import '../../config/url_utils.dart';
import 'package:shimmer/shimmer.dart';
import '../../components/error_retry_widget.dart';

class HomeCategoryIcons extends ConsumerStatefulWidget {
  const HomeCategoryIcons({super.key});

  @override
  ConsumerState<HomeCategoryIcons> createState() => _HomeCategoryIconsState();
}

class _HomeCategoryIconsState extends ConsumerState<HomeCategoryIcons> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final activeDigitalAsync = ref.watch(digitalActiveCategoriesProvider);
    final digitalConfigAsync = ref.watch(digitalConfigProvider);
    final digitalConfig = digitalConfigAsync.value;

    final hasActiveDigitalCats = activeDigitalAsync.value != null &&
        activeDigitalAsync.value!.isNotEmpty;
    final showDigital = (digitalConfig?.hasActiveProducts ?? (hasActiveDigitalCats)) &&
        hasActiveDigitalCats;
    final digitalTitle = (digitalConfig?.title.isNotEmpty == true)
        ? digitalConfig!.title
        : 'Digital Produk';

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty && !showDigital) return const SizedBox.shrink();

        final totalCount = categories.length + (showDigital ? 2 : 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Kategori Pilihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  if (showDigital && index == 0) {
                    return GestureDetector(
                      onTap: () => context.push('/digital-category'),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: (digitalConfig?.iconUrl.isNotEmpty == true)
                                  ? ClipOval(
                                      child: CustomNetworkImage(
                                        digitalConfig!.iconUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.deepOrange,
                                          size: 28,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.deepOrange,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              digitalTitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (index == totalCount - 1) {
                    return GestureDetector(
                      onTap: () => context.push('/all-categories'),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grid_view,
                                color: Colors.black54,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final catIndex = showDigital ? (index - 1) : index;
                  final cat = categories[catIndex];
                  return GestureDetector(
                    onTap: () => context.push('/search', extra: cat.id),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  (cat.imageUrl != null &&
                                      cat.imageUrl!.isNotEmpty)
                                  ? CustomNetworkImage(
                                      UrlUtils.formatImageUrl(cat.imageUrl!),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, _, _) => Icon(
                                        Icons.category_outlined,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    )
                                  : Icon(
                                      Icons.category_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ScrollIndicator(
              scrollController: _scrollController,
              width: 50,
              height: 5,
              indicatorWidth: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[300],
              ),
              indicatorDecoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kategori Pilihan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.65),
                        highlightColor: Colors.white,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.65),
                        highlightColor: Colors.white,
                        child: Container(
                          width: 50,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      error: (error, _) => ErrorRetryWidget(
        height: 100,
        onRetry: () => ref.refresh(homeCategoriesProvider),
      ),
    );
  }
}
