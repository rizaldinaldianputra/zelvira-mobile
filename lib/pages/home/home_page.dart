import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zelvira/riverpod/wishlist_provider.dart';
import '../../components/home/home_app_bar.dart';
import '../../components/home/home_search_bar.dart';
import '../../components/home/home_promo_carousel.dart';
import '../../components/home/home_category_icons.dart';
import '../../components/home/home_flash_sale.dart';
import '../../components/home/home_trending_list.dart';
import '../../components/home/home_section_title.dart';
import '../../components/home/home_news_list.dart';
import '../../components/home/home_featured_grid.dart';
import '../../riverpod/home_provider.dart';
import '../error_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch core providers to detect full-page errors
    final categoriesState = ref.watch(homeCategoriesProvider);

    if (categoriesState.isLoading) {
      return _buildSkeletonHome();
    }

    if (categoriesState.hasError) {
      return ErrorPage(
        onRetryAsync: () async {
          try {
            await Future.wait([
              ref.refresh(homeCategoriesProvider.future),
              ref.refresh(homeSectionsProvider.future),
              ref.refresh(homePromoBannersProvider.future),
              ref.refresh(homeTrendingContentProvider.future),
              ref.refresh(homeFlashSaleContentProvider.future),
              ref.refresh(homeNewsContentProvider.future),
              ref.refresh(homeFeaturedProductsProvider.future),
              ref.refresh(digitalConfigProvider.future),
              ref.refresh(digitalActiveCategoriesProvider.future),
            ]);
            await ref.read(wishlistProvider.notifier).loadWishlist();
          } catch (_) {}
        },
      );
    }

    // Always render ALL sections — data availability handled inside each widget
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Future.wait([
              ref.refresh(homeSectionsProvider.future),
              ref.refresh(homePromoBannersProvider.future),
              ref.refresh(homeCategoriesProvider.future),
              ref.refresh(homeTrendingContentProvider.future),
              ref.refresh(homeFlashSaleContentProvider.future),
              ref.refresh(homeNewsContentProvider.future),
              ref.refresh(homeFeaturedProductsProvider.future),
              ref.refresh(digitalConfigProvider.future),
              ref.refresh(digitalActiveCategoriesProvider.future),
            ]);
            await ref.read(wishlistProvider.notifier).loadWishlist();
          } catch (_) {}
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const HomeSliverAppBar(),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: const [HomeSearchBar(), SizedBox(height: 24)],
                ),
              ),
            ),

            // ─── PROMO CAROUSEL ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: HomePromoCarousel(),
              ),
            ),

            // ─── CATEGORIES ──────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: HomeCategoryIcons(),
              ),
            ),

            // ─── FLASH SALE ───────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: HomeFlashSale(),
              ),
            ),

            // ─── TRENDING NOW ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HomeSectionTitle(
                        title: 'Trending Now',
                        onSeeAll: () => context.push('/trending'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const HomeTrendingList(),
                  ],
                ),
              ),
            ),

            // ─── NEWS & ARTICLES ──────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: HomeNewsList(),
              ),
            ),

            // ─── FEATURED PRODUCTS ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: HomeSectionTitle(
                  title: 'Featured Products',
                  onSeeAll: () => context.push('/featured-products'),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: HomeFeaturedGrid(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonHome() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Skeletonizer(
        enabled: true,
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            const HomeSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 48,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: HomeFeaturedGrid(),
            ),
          ],
        ),
      ),
    );
  }
}
