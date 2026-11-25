import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MembershipTier {
  bronze,
  gold,
  platinum,
}

extension MembershipTierExtension on MembershipTier {
  String get name {
    switch (this) {
      case MembershipTier.bronze:
        return 'Bronze';
      case MembershipTier.gold:
        return 'Gold';
      case MembershipTier.platinum:
        return 'Platinum';
    }
  }

  double get discount {
    switch (this) {
      case MembershipTier.bronze:
        return 0.0;
      case MembershipTier.gold:
        return 0.05;
      case MembershipTier.platinum:
        return 0.10;
    }
  }

  int get requiredPoints {
    switch (this) {
      case MembershipTier.bronze:
        return 0;
      case MembershipTier.gold:
        return 100;
      case MembershipTier.platinum:
        return 300;
    }
  }
}

class MembershipState {
  final MembershipTier tier;
  final int points;

  MembershipState({required this.tier, required this.points});
}

class MembershipNotifier extends StateNotifier<MembershipState> {
  MembershipNotifier() : super(MembershipState(tier: MembershipTier.bronze, points: 20)) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierIndex = prefs.getInt('membership_tier') ?? 0;
      final points = prefs.getInt('membership_points') ?? 20;
      state = MembershipState(
        tier: MembershipTier.values[tierIndex],
        points: points,
      );
    } catch (_) {}
  }

  Future<void> addPoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newPoints = state.points + amount;

    MembershipTier newTier = state.tier;
    if (newPoints >= MembershipTier.platinum.requiredPoints) {
      newTier = MembershipTier.platinum;
    } else if (newPoints >= MembershipTier.gold.requiredPoints) {
      newTier = MembershipTier.gold;
    } else {
      newTier = MembershipTier.bronze;
    }

    state = MembershipState(tier: newTier, points: newPoints);
    await prefs.setInt('membership_tier', newTier.index);
    await prefs.setInt('membership_points', newPoints);
  }

  Future<void> upgradeTier() async {
    if (state.tier == MembershipTier.bronze) {
      await addPoints(100 - state.points);
    } else if (state.tier == MembershipTier.gold) {
      await addPoints(300 - state.points);
    }
  }
}

final membershipProvider = StateNotifierProvider<MembershipNotifier, MembershipState>((ref) {
  return MembershipNotifier();
});
