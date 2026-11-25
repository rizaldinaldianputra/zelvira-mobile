import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_style.dart';
import '../../riverpod/auth_provider.dart';
import '../../riverpod/voucher_provider.dart';
import '../../models/voucher_model.dart';
import '../../models/user_model.dart';
import 'dart:ui';

class VoucherListPage extends ConsumerStatefulWidget {
  const VoucherListPage({super.key});

  @override
  ConsumerState<VoucherListPage> createState() => _VoucherListPageState();
}

class _VoucherListPageState extends ConsumerState<VoucherListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getUserTier(int points) {
    if (points >= 300) return 'PLATINUM';
    if (points >= 100) return 'GOLD';
    return 'BRONZE';
  }

  bool _isEligible(String target, String userTier) {
    if (target == 'ALL') return true;
    if (target == 'GOLD' && (userTier == 'GOLD' || userTier == 'PLATINUM')) {
      return true;
    }
    if (target == 'PLATINUM' && userTier == 'PLATINUM') return true;
    if (target == 'BRONZE') return true;
    return false;
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(voucherProvider.notifier).loadVouchers(),
      Future(() => ref.refresh(authProvider)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final voucherState = ref.watch(voucherProvider);

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND GRADIENT & SHAPES
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFEAEE),
                  Color(0xFFF9FAFC),
                  Color(0xFFE8F0FE),
                ],
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Column(
              children: [
                // CUSTOM APP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Voucher & Promo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,

                      // Background active memenuhi lebar tab
                      indicatorSize: TabBarIndicatorSize.tab,

                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black54,

                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),

                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),

                      dividerColor: Colors.transparent,

                      tabs: const [
                        Tab(text: 'Tersedia'),
                        Tab(text: 'Milik Saya'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TAB VIEW CONTENT
                Expanded(
                  child: voucherState.isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: 4,
                            itemBuilder: (_, _) => Container(
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // TAB 1: Available Vouchers
                            _buildAvailableTab(authState, voucherState),

                            // TAB 2: Claimed Vouchers
                            _buildClaimedTab(voucherState),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(
    AsyncValue<UserModel?> authState,
    VoucherState voucherState,
  ) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: authState.when(
        data: (user) {
          if (user == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 150),
                Center(child: Text('Silahkan login terlebih dahulu')),
              ],
            );
          }

          final userTier = _getUserTier(user.points);

          if (voucherState.available.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 150),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada voucher tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: voucherState.available.length,
            itemBuilder: (context, index) {
              final voucher = voucherState.available[index];
              final eligible = _isEligible(voucher.targetMembership, userTier);
              return _buildTicketCard(
                voucher: voucher,
                isEligible: eligible,
                onAction: () async {
                  try {
                    await ref
                        .read(voucherProvider.notifier)
                        .claim(voucher.code);
                    if (context.mounted) {
                      AppToast.success(
                        context,
                        'Voucher ${voucher.code} berhasil diklaim!',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(
                        context,
                        'Gagal klaim voucher: ${e.toString()}',
                      );
                    }
                  }
                },
                actionLabel: 'KLAIM',
              );
            },
          );
        },
        loading: () => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (_, _) => Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 150),
            Center(child: Text('Error loading user profile: $err')),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimedTab(VoucherState voucherState) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: voucherState.claimed.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 150),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada voucher yang diklaim',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: voucherState.claimed.length,
              itemBuilder: (context, index) {
                final claimedVoucher = voucherState.claimed[index];
                return _buildTicketCard(
                  voucher: claimedVoucher.voucher,
                  isEligible: true,
                  actionLabel: 'KLAIMED',
                  isClaimed: true,
                  usageCount: claimedVoucher.usageCount,
                );
              },
            ),
    );
  }

  Widget _buildTicketCard({
    required VoucherModel voucher,
    required bool isEligible,
    required String actionLabel,
    VoidCallback? onAction,
    bool isClaimed = false,
    int usageCount = 0,
  }) {
    // Determine membership badge styling
    Color badgeColor = Colors.grey.shade600;
    String badgeLabel = 'ALL USER';
    if (voucher.targetMembership == 'GOLD') {
      badgeColor = Colors.amber.shade700;
      badgeLabel = 'GOLD ONLY';
    } else if (voucher.targetMembership == 'PLATINUM') {
      badgeColor = Colors.purple.shade700;
      badgeLabel = 'PLATINUM ONLY';
    } else if (voucher.targetMembership == 'BRONZE') {
      badgeColor = Colors.deepOrange.shade700;
      badgeLabel = 'BRONZE ONLY';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isEligible ? 0.75 : 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isEligible ? 0.6 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // LEFT COLORED TIER BAR
              Container(width: 6, color: isEligible ? badgeColor : Colors.grey),

              // VOUCHER DETAILS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Membership Badge & Expiry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isEligible ? badgeColor : Colors.grey)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isEligible ? badgeColor : Colors.grey,
                              ),
                            ),
                          ),
                          if (voucher.validUntil != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  voucher.validUntil!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Discount Amount
                      Text(
                        'Potongan Rp ${voucher.discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEligible ? Colors.black87 : Colors.black38,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Min Purchase
                      Text(
                        'Min. Belanja: Rp ${voucher.minPurchase.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isEligible ? Colors.black54 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Code Tag & usage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              voucher.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: isEligible
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (isClaimed)
                            Text(
                              'Digunakan: $usageCount kali',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // DOTTED DIVIDER
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: DottedLinePainter(color: Colors.grey.shade300),
              ),

              // ACTION BUTTON SIDE
              Container(
                width: 100,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: isClaimed
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KLAIMED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      )
                    : !isEligible
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'LOCKED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black26,
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          elevation: 0,
                        ),
                        onPressed: onAction,
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
