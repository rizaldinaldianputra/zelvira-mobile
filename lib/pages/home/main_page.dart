import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:feature_discovery/feature_discovery.dart';
import '../../config/app_style.dart';
import '../../config/feature_ids.dart';
import '../../components/common/feature_overlay_prompt.dart';
import 'home_page.dart';
import 'news_page.dart';
import 'profile_page.dart';
import '../cart/cart_page.dart';
import '../order/order_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../riverpod/wishlist_provider.dart';

class MainPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late int currentIndex;

  final List<Widget> pages = [
    const HomePage(),
    const NewsPage(),
    const CartPage(),
    const OrderListPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    // Mengambil indeks tab dari route, misalnya /home/3.
    currentIndex = widget.initialIndex.clamp(0, pages.length - 1);

    Future.microtask(() {
      ref.read(wishlistProvider.notifier).loadWishlist();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeDiscovery();
    });
  }

  Future<void> _checkFirstTimeDiscovery() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('has_seen_home_intro') ?? false;

    if (!hasSeenIntro) {
      await _showHomeIntro();
      await prefs.setBool('has_seen_home_intro', true);
    }

    if (mounted) {
      await FeatureDiscoveryHelper.checkAndStartDiscovery(context);
    }
  }

  Future<void> _showHomeIntro() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // BLUR BACKGROUND
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // SLIDES
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 500,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildIntroSlide(
                                      icon: Icons.explore_rounded,
                                      title: 'Selamat Datang!',
                                      description:
                                          'Jelajahi koleksi fashion eksklusif kami langsung dari beranda Anda.',
                                    ),
                                    _buildIntroSlide(
                                      icon: Icons.newspaper_rounded,
                                      title: 'Info Terkini',
                                      description:
                                          'Dapatkan tren terbaru dan berita fashion di tab News kami.',
                                    ),
                                    _buildIntroSlide(
                                      icon: Icons.shopping_bag_rounded,
                                      title: 'Siap Checkout?',
                                      description:
                                          'Kelola keranjang dan pantau pesanan Anda dengan mudah dalam satu aplikasi.',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const TabPageSelector(
                                color: Colors.black12,
                                selectedColor: AppColors.primary,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text('MULAI BELANJA'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIntroSlide({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 60, color: AppColors.primary),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: ZelixaFeatureOverlay(
        featureId: FeatureIds.bottomNav,
        tapTarget: const Icon(Icons.shopping_bag, color: AppColors.primary),
        title: 'Navigasi Menu Utama',
        description:
            'Akses Beranda, Berita Tren Fashion, Keranjang Belanja, Riwayat Pesanan, dan Profil Akun.',
        step: 5,
        isLast: true,
        contentLocation: ContentLocation.above,
        child: ConvexAppBar(
          style: TabStyle.fixedCircle,
          backgroundColor: Colors.white,
          color: Colors.grey,
          activeColor: AppColors.primary,
          shadowColor: Colors.transparent,
          initialActiveIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            TabItem(icon: Icons.home_rounded, title: 'Beranda'),
            TabItem(icon: Icons.newspaper_rounded, title: 'News'),
            TabItem(icon: Icons.shopping_bag, title: 'Keranjang'),
            TabItem(icon: Icons.receipt_long, title: 'Pesanan'),
            TabItem(icon: Icons.person_rounded, title: 'Profil'),
          ],
        ),
      ),
    );
  }
}
