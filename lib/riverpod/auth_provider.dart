import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

import 'order_provider.dart';
import 'news_provider.dart';
import 'home_provider.dart';
import 'membership_provider.dart';
import 'cart_provider.dart';
import 'wishlist_provider.dart';
import 'voucher_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final SessionService _sessionService = SessionService();

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    checkLoginStatus();
  }

  void setUser(UserModel? user) {
    state = AsyncValue.data(user);
  }

  Future<void> checkLoginStatus() async {
    state = const AsyncValue.loading();
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Try to get from SharedPreferences first for instant display
        final cachedUser = await _sessionService.getUser();
        if (cachedUser != null) {
          state = AsyncValue.data(cachedUser);
        }

        // Then refresh from API
        final profile = await _authService.getProfile();
        state = AsyncValue.data(profile);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      final authService = ref.read(authServiceProvider);
      return AuthNotifier(authService);
    });

/// Comprehensive helper to refresh ALL tabs & modules when login / OTP verification succeeds
Future<void> refreshAllAppData(WidgetRef ref) async {
  // 1. Auth Profile & Membership
  await ref.read(authProvider.notifier).checkLoginStatus();
  ref.invalidate(membershipProvider);

  // 2. Orders (Pesanan Saya)
  ref.read(orderProvider.notifier).fetchOrders();

  // 3. News
  ref.read(newsProvider.notifier).fetchNews();
  ref.invalidate(homeNewsContentProvider);

  // 4. Beranda (Home contents)
  ref.invalidate(homeCategoriesProvider);
  ref.invalidate(homeSectionsProvider);
  ref.invalidate(homePromoBannersProvider);
  ref.invalidate(homeTrendingContentProvider);
  ref.invalidate(homeFlashSaleContentProvider);
  ref.invalidate(homeFeaturedProductsProvider);
  ref.invalidate(digitalConfigProvider);
  ref.invalidate(digitalActiveCategoriesProvider);

  // 5. Cart & Wishlist & Vouchers
  ref.read(cartProvider.notifier).fetchCart();
  ref.read(wishlistProvider.notifier).loadWishlist();
  ref.invalidate(voucherProvider);
}
