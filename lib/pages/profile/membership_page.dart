import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import '../../config/app_style.dart';
import '../../riverpod/membership_provider.dart';
import 'dart:ui';

class MembershipPage extends ConsumerWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(membershipProvider);
    final notifier = ref.read(membershipProvider.notifier);

    // Calculate progress
    String nextTierName = '';
    int pointsNeeded = 0;
    double progress = 1.0;

    if (membership.tier == MembershipTier.bronze) {
      nextTierName = 'Gold';
      pointsNeeded = 100 - membership.points;
      progress = membership.points / 100.0;
    } else if (membership.tier == MembershipTier.gold) {
      nextTierName = 'Platinum';
      pointsNeeded = 300 - membership.points;
      progress = (membership.points - 100) / 200.0;
    } else {
      nextTierName = 'Max Tier Reached';
      pointsNeeded = 0;
      progress = 1.0;
    }

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Membership Tier',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          // BACKGROUND
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

          // SHAPES
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // TIER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tierColor.withValues(alpha: 0.85),
                          tierColor.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tierIcon,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            Text(
                              '${membership.points} PTS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CURRENT TIER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          membership.tier.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PROGRESS SECTION
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              membership.tier != MembershipTier.platinum
                                  ? 'Progress to $nextTierName'
                                  : 'Highest level reached!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            if (membership.tier != MembershipTier.platinum)
                              Text(
                                '$pointsNeeded PTS left',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tierColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  await notifier.addPoints(50);
                                  toastification.show(
                                    context: context,
                                    title: const Text('Points Claimed!'),
                                    description: const Text(
                                      '+50 Points added to your balance',
                                    ),
                                    type: ToastificationType.success,
                                    autoCloseDuration: const Duration(
                                      seconds: 2,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Earn +50 Points',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (membership.tier != MembershipTier.platinum)
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () async {
                                    await notifier.upgradeTier();
                                    toastification.show(
                                      context: context,
                                      title: const Text('Tier Upgraded!'),
                                      description: const Text(
                                        'Congratulations, your tier has been upgraded!',
                                      ),
                                      type: ToastificationType.success,
                                      autoCloseDuration: const Duration(
                                        seconds: 2,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Level Up Tier',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PERKS LIST
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'Membership Perks'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  _buildPerksCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerksCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildPerkRow(
            icon: Icons.military_tech_outlined,
            iconColor: const Color(0xFFCD7F32),
            title: 'Bronze Member Perks',
            desc: 'Standard member access. Regular offers.',
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          _buildPerkRow(
            icon: Icons.workspace_premium,
            iconColor: const Color(0xFFFFD700),
            title: 'Gold Member Perks',
            desc: '5% Extra discount on all items & Free shipping.',
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          _buildPerkRow(
            icon: Icons.diamond,
            iconColor: const Color(0xFF9E9E9E),
            title: 'Platinum Member Perks',
            desc: '10% Extra discount, Free shipping, & Priority Support.',
          ),
        ],
      ),
    );
  }

  Widget _buildPerkRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}
