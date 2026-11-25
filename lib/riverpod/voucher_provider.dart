import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher_model.dart';
import '../models/user_voucher_model.dart';
import '../services/voucher_service.dart';

final voucherServiceProvider = Provider<VoucherService>((ref) {
  return VoucherService();
});

class VoucherState {
  final List<VoucherModel> available;
  final List<UserVoucherModel> claimed;
  final bool isLoading;
  final String? errorMessage;

  VoucherState({
    required this.available,
    required this.claimed,
    required this.isLoading,
    this.errorMessage,
  });

  VoucherState copyWith({
    List<VoucherModel>? available,
    List<UserVoucherModel>? claimed,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VoucherState(
      available: available ?? this.available,
      claimed: claimed ?? this.claimed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class VoucherNotifier extends StateNotifier<VoucherState> {
  final VoucherService _service;

  VoucherNotifier(this._service)
      : super(VoucherState(available: [], claimed: [], isLoading: false)) {
    loadVouchers();
  }

  Future<void> loadVouchers() async {
    state = state.copyWith(isLoading: true);
    try {
      final available = await _service.getAvailableVouchers();
      final claimed = await _service.getMyVouchers();
      state = VoucherState(
        available: available,
        claimed: claimed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> claim(String code) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.claimVoucher(code);
      await loadVouchers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final voucherProvider = StateNotifierProvider<VoucherNotifier, VoucherState>((ref) {
  final service = ref.read(voucherServiceProvider);
  return VoucherNotifier(service);
});
