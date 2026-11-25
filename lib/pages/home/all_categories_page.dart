import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zelvira/config/app_style.dart';
import '../../riverpod/home_provider.dart';

class AllCategoriesPage extends ConsumerWidget {
  const AllCategoriesPage({super.key});

  IconData _resolveIcon(String code, String? iconName, bool isPostpaid) {
    final c = code.toLowerCase();
    if (c.contains('pulsa')) return Icons.phone_android;
    if (c.contains('data')) return Icons.wifi;
    if (c.contains('pln') && !isPostpaid) return Icons.electric_bolt;
    if (c.contains('pln') && isPostpaid) return Icons.power;
    if (c.contains('game')) return Icons.videogame_asset;
    if (c.contains('bpjs')) return Icons.health_and_safety;
    if (c.contains('pdam')) return Icons.water_drop;
    if (c.contains('internet')) return Icons.router;
    if (c.contains('gas')) return Icons.local_fire_department;
    if (c.contains('voucher')) return Icons.confirmation_number;
    if (c.contains('paket')) return Icons.call;
    if (c.contains('masa aktif')) return Icons.access_time;
    return Icons.account_balance_wallet;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final activeDigitalAsync = ref.watch(digitalActiveCategoriesProvider);
    final digitalConfigAsync = ref.watch(digitalConfigProvider);
    final digitalConfig = digitalConfigAsync.value;

    final activeCats = activeDigitalAsync.value;
    final hasActiveDigital = (digitalConfig?.hasActiveProducts ?? (activeCats != null && activeCats.isNotEmpty)) &&
        activeCats != null &&
        activeCats.isNotEmpty;
    final digitalGroupTitle = (digitalConfig?.title.isNotEmpty == true)
        ? digitalConfig!.title
        : 'Produk Digital';

    final visibleShortcuts = (activeCats ?? [])
        .where((c) => c.isActive)
        .map((c) => _DigitalShortcutItem(
              c.name,
              c.code,
              _resolveIcon(c.code, c.iconName, c.isPostpaid),
              c.isPostpaid,
              iconUrl: c.iconUrl,
            ))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Semua Kategori')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PPOB / Digital Group - Only show if active digital categories exist
            if (hasActiveDigital && visibleShortcuts.isNotEmpty) ...[
              Text(
                digitalGroupTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...visibleShortcuts.take(7).map(
                        (s) => _buildDigitalCategory(
                          context,
                          s.title,
                          s.category,
                          s.icon,
                          iconUrl: s.iconUrl,
                          isPostpaid: s.isPostpaid,
                        ),
                      ),
                  _buildDigitalCategory(
                    context,
                    'Lainnya',
                    '',
                    Icons.grid_view,
                    onTap: () => context.push('/digital-category'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Physical Products Group
            const Text(
              'Belanja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('Tidak ada kategori belanja.');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return GestureDetector(
                      onTap: () => context.push('/search', extra: cat.id),
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
                              child: cat.imageUrl != null &&
                                      cat.imageUrl!.isNotEmpty
                                  ? CustomNetworkImage(
                                      cat.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => Skeletonizer(
                enabled: true,
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    8,
                    (index) => Column(
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
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (error, _) =>
                  const Center(child: Text('Gagal memuat kategori')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalCategory(
    BuildContext context,
    String title,
    String category,
    IconData icon, {
    String? iconUrl,
    bool? isPostpaid,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () => context.push(
            '/digital-products?category=$category&title=${Uri.encodeComponent(title)}${isPostpaid != null ? '&isPostpaid=$isPostpaid' : ''}',
          ),
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
            child: (iconUrl != null && iconUrl.isNotEmpty)
                ? ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.network(
                        iconUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(icon, color: Colors.deepOrange, size: 28),
                      ),
                    ),
                  )
                : Icon(icon, color: Colors.deepOrange, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DigitalShortcutItem {
  final String title;
  final String category;
  final IconData icon;
  final bool isPostpaid;
  final String? iconUrl;

  _DigitalShortcutItem(
    this.title,
    this.category,
    this.icon,
    this.isPostpaid, {
    this.iconUrl,
  });
}
