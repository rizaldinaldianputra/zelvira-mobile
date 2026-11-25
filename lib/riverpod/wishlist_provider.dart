import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

class WishlistState {
  final List<WishlistItem> items;
  final Set<int> wishlistedIds;
  final bool isLoading;

  WishlistState({
    this.items = const [],
    this.wishlistedIds = const {},
    this.isLoading = false,
  });

  WishlistState copyWith({
    List<WishlistItem>? items,
    Set<int>? wishlistedIds,
    bool? isLoading,
  }) {
    return WishlistState(
      items: items ?? this.items,
      wishlistedIds: wishlistedIds ?? this.wishlistedIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _service;

  WishlistNotifier(this._service) : super(WishlistState()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _service.getWishlist();
      final ids = items.map((i) => i.product.id).toSet();
      state = state.copyWith(items: items, wishlistedIds: ids, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> toggleWishlist(Product product) async {
    final currentIds = Set<int>.from(state.wishlistedIds);
    final isCurrentlyIn = currentIds.contains(product.id);

    // Optimistic UI update
    if (isCurrentlyIn) {
      currentIds.remove(product.id);
    } else {
      currentIds.add(product.id);
    }

    state = state.copyWith(wishlistedIds: currentIds);

    try {
      await _service.toggleWishlist(product.id);
      // Refresh real list in background
      final items = await _service.getWishlist();
      final updatedIds = items.map((i) => i.product.id).toSet();
      state = state.copyWith(items: items, wishlistedIds: updatedIds);
      return !isCurrentlyIn;
    } catch (e) {
      // Revert if error
      if (isCurrentlyIn) {
        currentIds.add(product.id);
      } else {
        currentIds.remove(product.id);
      }
      state = state.copyWith(wishlistedIds: currentIds);
      rethrow;
    }
  }

  Future<void> removeItem(int wishlistItemId, int productId) async {
    final currentIds = Set<int>.from(state.wishlistedIds)..remove(productId);
    final currentItems = state.items.where((i) => i.id != wishlistItemId).toList();
    state = state.copyWith(items: currentItems, wishlistedIds: currentIds);

    try {
      await _service.removeFromWishlist(wishlistItemId);
    } catch (e) {
      loadWishlist();
      rethrow;
    }
  }

  bool isWishlisted(int productId) {
    return state.wishlistedIds.contains(productId);
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final service = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(service);
});

final isProductWishlistedProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(wishlistProvider).wishlistedIds.contains(productId);
});
