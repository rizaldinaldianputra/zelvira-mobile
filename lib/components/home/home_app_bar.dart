import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:zelvira/components/home/shimemr_logo.dart';
import '../../config/app_style.dart';
import '../../config/feature_ids.dart';
import '../../services/notification_service.dart';
import '../common/feature_overlay_prompt.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        _NotificationButton(),
        IconButton(
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.black87,
          ),
          tooltip: 'Chat Support',
          onPressed: () => context.push('/support/chat'),
        ),
        IconButton(
          icon: const Icon(
            Icons.favorite_border_rounded,
            color: Colors.black87,
          ),
          tooltip: 'Wishlist',
          onPressed: () => context.push('/wishlist'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NotificationButton extends StatefulWidget {
  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final count = await NotificationService().getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
          tooltip: 'Notifikasi',
          onPressed: () async {
            await context.push('/notifications');
            _fetchUnread();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4D4D),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: ShimmerLogo(),
      actions: [
        ZelixaFeatureOverlay(
          featureId: FeatureIds.notification,
          tapTarget: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
          ),
          title: 'Notifikasi & Promo',
          description:
              'Pantau pembaruan status pesanan, pengiriman paket, dan kabar promo eksklusif setiap saat.',
          step: 2,
          contentLocation: ContentLocation.below,
          child: _NotificationButton(),
        ),
        ZelixaFeatureOverlay(
          featureId: FeatureIds.chatSupport,
          tapTarget: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
          ),
          title: 'Layanan Bantuan CS',
          description:
              'Butuh bantuan produk atau transaksi? Hubungi customer support Zelvira secara langsung lewat obrolan live.',
          step: 3,
          contentLocation: ContentLocation.below,
          child: IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.black87,
            ),
            tooltip: 'Chat Support',
            onPressed: () => context.push('/support/chat'),
          ),
        ),
        ZelixaFeatureOverlay(
          featureId: FeatureIds.wishlist,
          tapTarget: const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.primary,
          ),
          title: 'Daftar Keinginan',
          description:
              'Simpan koleksi fashion idaman Anda ke wishlist untuk dibeli dengan mudah kapan pun Anda inginkan.',
          step: 4,
          contentLocation: ContentLocation.below,
          child: IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.black87,
            ),
            tooltip: 'Wishlist',
            onPressed: () => context.push('/wishlist'),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
