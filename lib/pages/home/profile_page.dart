import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_style.dart';
import '../../config/url_utils.dart';
import '../../riverpod/auth_provider.dart';
import '../../riverpod/membership_provider.dart';
import '../../models/user_model.dart';
import 'dart:ui';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkLoginStatus();
      ref.invalidate(membershipProvider);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(authProvider.notifier).checkLoginStatus();
    ref.invalidate(membershipProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final membership = ref.watch(membershipProvider);

    return Scaffold(
      body: Stack(
        children: [
          // GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFEAEE), // Soft pink/white
                  Color(0xFFF9FAFC), // White background
                  Color(0xFFE8F0FE), // Soft blue
                ],
              ),
            ),
          ),

          // DECORATIVE SHAPES
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 350,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // BLUR EFFECT OVER SHAPES
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          // CONTENT
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          _buildHeaderIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {
                              context.push('/profile/settings');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileCard(context, authState, membership),
                    const SizedBox(height: 16),

                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildMenuSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PROFILE CARD FLOATING
  Widget _buildProfileSkeletonCard() {
    return Skeletonizer(
      enabled: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 130,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AsyncValue<UserModel?> authState,
    MembershipState membership,
  ) {
    Color tierColor;
    IconData tierIcon;
    switch (membership.tier) {
      case MembershipTier.bronze:
        tierColor = const Color(0xFFCD7F32);
        tierIcon = Icons.military_tech_outlined;
        break;
      case MembershipTier.gold:
        tierColor = const Color(0xFFFFD700);
        tierIcon = Icons.workspace_premium;
        break;
      case MembershipTier.platinum:
        tierColor = const Color(0xFF9E9E9E);
        tierIcon = Icons.diamond;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: authState.when(
        data: (user) {
          if (user == null) {
            return _buildProfileSkeletonCard();
          }

          return Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile-edit', extra: user),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              (user.profilePicture != null &&
                                  user.profilePicture!.isNotEmpty)
                              ? UrlUtils.formatImageUrl(user.profilePicture)
                              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.fullName ?? 'User')}&background=random',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 70,
                              height: 70,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.network(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.fullName ?? 'User')}&background=random',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/profile-edit', extra: user),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName ?? 'Zelvira User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isNotEmpty
                            ? user.email
                            : (user.phoneNumber ?? ''),
                        style: const TextStyle(color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(tierIcon, size: 12, color: tierColor),
                          const SizedBox(width: 2),
                          Text(
                            membership.tier.name.toUpperCase(),
                            style: TextStyle(
                              background: Paint()
                                ..color = tierColor.withValues(alpha: 0.1)
                                ..style = PaintingStyle.fill,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          );
        },
        loading: () => _buildProfileSkeletonCard(),
        error: (err, _) => _buildProfileSkeletonCard(),
      ),
    );
  }

  // QUICK ACTION (ecommerce feel)
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _quickItem(Icons.shopping_bag, "Orders", () {
            context.go('/home/3');
          }),
          _quickItem(
            Icons.favorite,
            "Wishlist",
            () => context.push('/wishlist'),
          ),
          _quickItem(Icons.star_border, "Rating", () {
            context.push('/rating');
          }),
          _quickItem(Icons.star, "Points", () => context.push('/point')),
        ],
      ),
    );
  }

  Widget _quickItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // MENU SECTION
  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Aktivitas & Akun"),
          _buildGroupCard([
            _menuRowItem(
              context,
              Icons.account_balance_wallet,
              "Wallet",
              () => context.push('/wallet'),
            ),
            _menuRowItem(
              context,
              Icons.location_on_outlined,
              "Address",
              () => context.push('/address-list'),
            ),
            _menuRowItem(
              context,
              Icons.settings_outlined,
              "Settings",
              () => context.push('/profile/settings'),
            ),
            _menuRowItem(
              context,
              Icons.confirmation_number_outlined,
              "Voucher Saya",
              () => context.push('/profile/vouchers'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader("Pusat Informasi"),
          _buildGroupCard([
            _menuRowItem(
              context,
              Icons.help_outline_rounded,
              "Pusat Bantuan",
              () => context.push('/support/help'),
            ),
            _menuRowItem(
              context,
              Icons.question_answer_outlined,
              "FAQ (Tanya Jawab)",
              () => context.push('/support/faq'),
            ),
            _menuRowItem(
              context,
              Icons.shield_outlined,
              "Kebijakan Privasi",
              () => context.push('/support/privacy'),
            ),
            _menuRowItem(
              context,
              Icons.info_outline_rounded,
              "Tentang Zelvira",
              () => context.push('/support/about'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildGroupCard([
            _menuRowItem(
              context,
              Icons.logout_rounded,
              "Logout",
              () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              isDanger: true,
              showDivider: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1.1,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuRowItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDanger ? Colors.red : AppColors.primary).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDanger ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDanger ? Colors.red : Colors.black87,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDanger
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.black38,
              size: 20,
            ),
            onTap: onTap,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }
}
