import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zelvira/models/cart_model.dart';
import 'package:zelvira/riverpod/order_provider.dart';
import '../../config/app_style.dart';
import '../../riverpod/cart_provider.dart';
import '../../riverpod/checkout_provider.dart' hide orderServiceProvider;
import '../../riverpod/address_provider.dart';
import '../../riverpod/shipping_provider.dart';
import '../../models/checkout_model.dart';
import '../../models/address_model.dart';
import '../../models/shipping_model.dart';
import '../../services/voucher_service.dart';
import '../../services/wallet_service.dart';
import '../../models/voucher_model.dart';
import 'package:toastification/toastification.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/midtrans_config.dart';
import '../../config/currency_utils.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? buyNowData;

  const CheckoutPage({super.key, this.buyNowData});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  AddressResponse? selectedAddress;
  ShippingCourierResponse? selectedCourier;
  bool _addressInitialized = false;

  String? appliedVoucher;
  double discount = 0;

  // Payment method: 'MIDTRANS' or 'WALLET'
  String _selectedPaymentMethod = 'MIDTRANS';
  double _walletBalance = 0;
  int _userPoints = 0;
  bool _usePoints = false;
  bool _isLoadingWallet = false;

  bool _isProcessing = false;
  MidtransSDK? _midtrans;
  OrderResponse? _currentOrder;
  final VoucherService _voucherService = VoucherService();
  final WalletService _walletService = WalletService();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _checkAuth();
    _initMidtrans();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          toastification.show(
            context: context,
            title: const Text('Silakan Login'),
            description: const Text(
              'Silakan login terlebih dahulu untuk checkout.',
            ),
            type: ToastificationType.warning,
            autoCloseDuration: const Duration(seconds: 2),
          );
          context.go('/login');
        }
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _isLoadingWallet = true);
    try {
      final wallet = await _walletService.getWalletInfo();
      if (mounted) {
        setState(() {
          _walletBalance = wallet.balance;
          _userPoints = wallet.points;
        });
      }
    } catch (e) {
      debugPrint('Failed to load wallet: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _initMidtrans() async {
    try {
      _midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: AppMidtransConfig.clientKey,
          merchantBaseUrl: AppMidtransConfig.merchantBaseUrl,
          colorTheme: ColorTheme(
            colorPrimary: AppColors.primary,
            colorPrimaryDark: AppColors.primary,
            colorSecondary: AppColors.primary,
          ),
        ),
      );
      _midtrans?.setTransactionFinishedCallback((result) async {
        debugPrint("Midtrans Finished callback: status = ${result.status}");
        if (_currentOrder != null) {
          // Immediately sync status from Midtrans
          await ref
              .read(orderServiceProvider)
              .syncPaymentStatus(_currentOrder!.id);
          ref.read(orderProvider.notifier).fetchOrders();
        }
        if (mounted) {
          final isSuccess =
              result.status == 'settlement' ||
              result.status == 'capture' ||
              result.status == 'success';
          _showPaymentResultDialog(
            context,
            isSuccess: isSuccess,
            orderId: _currentOrder?.id,
          );
        }
      });
    } catch (e) {
      debugPrint("Failed to initialize Midtrans SDK: $e");
    }
  }

  Future<void> _processCheckout() async {
    if (selectedAddress == null || selectedCourier == null) {
      toastification.show(
        context: context,
        title: const Text('Pilih alamat dan metode pengiriman terlebih dahulu'),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    // Stock validations before checkout
    if (widget.buyNowData != null) {
      final buyQty =
          int.tryParse(widget.buyNowData!['quantity']?.toString() ?? '1') ?? 1;
      final maxStock = int.tryParse(
        widget.buyNowData!['stock']?.toString() ?? '',
      );
      if (maxStock != null && maxStock > 0 && buyQty > maxStock) {
        toastification.show(
          context: context,
          title: const Text('Jumlah Melebihi Stok'),
          description: Text(
            'Pesanan ($buyQty) melebihi stok yang tersedia ($maxStock)',
          ),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
        return;
      }
    } else {
      final cartItems = ref.read(cartProvider).value ?? [];
      for (final item in cartItems) {
        if (item.stock <= 0) {
          toastification.show(
            context: context,
            title: const Text('Stok Habis'),
            description: Text(
              'Produk "${item.productName}" sudah habis. Harap hapus dari keranjang.',
            ),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
          return;
        }
        if (item.quantity > item.stock) {
          toastification.show(
            context: context,
            title: const Text('Jumlah Melebihi Stok'),
            description: Text(
              'Pesanan "${item.productName}" (${item.quantity}) melebihi stok yang tersedia (${item.stock}).',
            ),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
          return;
        }
      }
    }

    setState(() => _isProcessing = true);
    try {
      final currentSubtotal = (widget.buyNowData != null)
          ? ((widget.buyNowData!['price'] as num).toDouble() *
                (int.tryParse(
                      widget.buyNowData!['quantity']?.toString() ?? '1',
                    ) ??
                    1))
          : ref.read(cartTotalProvider);
      final currentShipping = selectedCourier?.cost ?? 0.0;
      final maxPoints = math.max(
        0,
        (currentSubtotal + currentShipping - discount).floor(),
      );
      final pointsToUse = _usePoints ? math.min(_userPoints, maxPoints) : 0;
      final pointsDiscount = pointsToUse * 1.0;
      final finalTotal = math.max(
        0.0,
        currentSubtotal + currentShipping - discount - pointsDiscount,
      );

      if (_selectedPaymentMethod == 'WALLET' && _walletBalance < finalTotal) {
        setState(() => _isProcessing = false);
        toastification.show(
          context: context,
          title: const Text('Saldo Wallet Tidak Cukup'),
          description: Text(
            'Saldo Anda (${CurrencyUtils.format(_walletBalance)}) tidak mencukupi untuk pembayaran sebesar ${CurrencyUtils.format(finalTotal)}.',
          ),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
        return;
      }

      final fullAddress = [
        selectedAddress!.addressLine,
        selectedAddress!.subdistrictName,
        selectedAddress!.districtName,
        selectedAddress!.cityName,
        selectedAddress!.provinceName,
        selectedAddress!.postalCode,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      final request = CheckoutRequest(
        shippingService: selectedCourier!.name,
        destinationSubdistrictId: selectedAddress!.subdistrictId,
        shippingAmount: selectedCourier!.cost,
        voucherCode: appliedVoucher,
        paymentMethod: _selectedPaymentMethod,
        shippingAddress: fullAddress,
        shippingRecipient: selectedAddress!.recipientName,
        shippingPhone: selectedAddress!.phoneNumber,
        pointsUsed: pointsToUse > 0 ? pointsToUse : null,
        productId: widget.buyNowData != null
            ? int.tryParse(
                    widget.buyNowData!['productId']?.toString() ?? '0',
                  ) ??
                  0
            : null,
        variantId: widget.buyNowData != null
            ? int.tryParse(widget.buyNowData!['variantId']?.toString() ?? '')
            : null,
        quantity: widget.buyNowData != null
            ? int.tryParse(widget.buyNowData!['quantity']?.toString() ?? '1') ??
                  1
            : null,
      );

      await ref.read(checkoutProvider.notifier).checkout(request);
      final checkoutState = ref.read(checkoutProvider);

      checkoutState.whenOrNull(
        data: (order) async {
          if (order == null) return;

          ref.read(cartProvider.notifier).clearCart();

          // WALLET: order created directly → show success immediately
          if (_selectedPaymentMethod == 'WALLET') {
            if (mounted) _showSuccessDialog(context, isWallet: true);
            return;
          }

          // MIDTRANS: launch payment UI
          _currentOrder = order;
          final snapUrl = AppMidtransConfig.resolvePaymentUrl(
            paymentUrl: order.paymentUrl,
            paymentToken: order.paymentToken,
          );

          bool sdkLaunched = false;
          if (_midtrans != null &&
              order.paymentToken != null &&
              order.paymentToken!.isNotEmpty) {
            try {
              await _midtrans!.startPaymentUiFlow(token: order.paymentToken!);
              sdkLaunched = true;
              // Wait for transactionFinishedCallback when native SDK runs
            } catch (e) {
              debugPrint("Failed to start Midtrans SDK: $e");
              sdkLaunched = false;
            }
          }

          if (!sdkLaunched) {
            if (snapUrl.isNotEmpty) {
              final uri = Uri.parse(snapUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.inAppWebView);
                if (_currentOrder != null) {
                  try {
                    await ref
                        .read(orderServiceProvider)
                        .syncPaymentStatus(_currentOrder!.id);
                    ref.read(orderProvider.notifier).fetchOrders();
                  } catch (_) {}
                }
                if (mounted) {
                  _showPaymentResultDialog(
                    context,
                    isSuccess: false,
                    orderId: _currentOrder?.id,
                  );
                }
              } else {
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Gagal membuka halaman pembayaran'),
                    type: ToastificationType.error,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                }
              }
            } else {
              if (mounted) _showSuccessDialog(context, isWallet: false);
            }
          }
        },
        error: (err, st) {
          toastification.show(
            context: context,
            title: Text('Checkout Gagal: $err'),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  double _calculateVoucherDiscount(
    VoucherModel voucher,
    double currentSubtotal,
  ) {
    if (voucher.discountType.toUpperCase() == 'PERCENTAGE') {
      double calc = currentSubtotal * (voucher.discountAmount / 100.0);
      if (voucher.maxDiscount != null && calc > voucher.maxDiscount!) {
        return voucher.maxDiscount!;
      }
      return calc;
    }
    return voucher.discountAmount;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final shippingState = ref.watch(shippingProvider);

    double subtotal = 0;
    List<dynamic> itemsToDisplay = [];

    if (widget.buyNowData != null) {
      final price = (widget.buyNowData!['price'] as num).toDouble();
      final qty =
          int.tryParse(widget.buyNowData!['quantity']?.toString() ?? '1') ?? 1;
      subtotal = price * qty;
      itemsToDisplay = [
        CartItemResponse(
          id: 0,
          productId:
              int.tryParse(
                widget.buyNowData!['productId']?.toString() ?? '0',
              ) ??
              0,
          productName: widget.buyNowData!['title'],
          productVariantId:
              int.tryParse(
                widget.buyNowData!['variantId']?.toString() ?? '0',
              ) ??
              0,
          size: widget.buyNowData!['size'] ?? '',
          color: widget.buyNowData!['color'] ?? '',
          groupName: '',
          price: price,
          discountPrice: price,
          quantity: qty,
          stock:
              int.tryParse(widget.buyNowData!['stock']?.toString() ?? '999') ??
              999,
          imageUrl: widget.buyNowData!['image'] ?? '',
        ),
      ];
    } else {
      subtotal = ref.watch(cartTotalProvider);
      cartState.whenData((items) => itemsToDisplay = items);
    }

    final double shippingCost = selectedCourier?.cost ?? 0.0;
    final int maxPointsUsable = math.max(
      0,
      (subtotal + shippingCost - discount).floor(),
    );
    final int pointsToUse = _usePoints
        ? math.min(_userPoints, maxPointsUsable)
        : 0;
    final double pointsDiscount = pointsToUse * 1000.0;
    final double total = math.max(
      0.0,
      subtotal + shippingCost - discount - pointsDiscount,
    );

    if (!_addressInitialized &&
        addressState is AsyncData &&
        addressState.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final addr = addressState.value!.first;
          setState(() {
            selectedAddress = addr;
            _addressInitialized = true;
          });
          // Use districtId for RajaOngkir cost calculation
          final destId = addr.districtId ?? addr.subdistrictId;
          ref.read(shippingProvider.notifier).calculateCost(destId);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: (widget.buyNowData == null)
          ? cartState.when(
              data: (cartItems) => _buildBody(
                cartItems,
                subtotal,
                shippingCost,
                total,
                pointsDiscount,
                pointsToUse,
                addressState,
                shippingState,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            )
          : _buildBody(
              itemsToDisplay,
              subtotal,
              shippingCost,
              total,
              pointsDiscount,
              pointsToUse,
              addressState,
              shippingState,
            ),
      bottomSheet:
          (widget.buyNowData != null ||
              (cartState.hasValue && cartState.value!.isNotEmpty))
          ? _buildBottomBar(total)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBody(
    List<dynamic> items,
    double subtotal,
    double shippingCost,
    double total,
    double pointsDiscount,
    int pointsToUse,
    AsyncValue<List<AddressResponse>> addressState,
    AsyncValue<List<ShippingCourierResponse>> shippingState,
  ) {
    if (items.isEmpty) {
      return const Center(child: Text("Keranjang kosong"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ADDRESS SECTION
          _buildSectionTitle('Alamat Pengiriman'),
          if (selectedAddress == null)
            _buildSelectableCard(
              icon: Icons.location_on,
              title: 'Pilih Alamat Pengiriman',
              subtitle: 'Belum ada alamat yang dipilih',
              trailing: 'Pilih',
              onTap: () =>
                  _showAddressModal(context, addressState.valueOrNull ?? []),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedAddress!.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (selectedAddress!.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Utama',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddressModal(
                          context,
                          addressState.valueOrNull ?? [],
                        ),
                        child: Text(
                          'Ubah',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selectedAddress!.recipientName} | ${selectedAddress!.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedAddress!.addressLine,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  // Show Raja Ongkir location hierarchy
                  Text(
                    [
                      if (selectedAddress!.subdistrictName.isNotEmpty)
                        selectedAddress!.subdistrictName,
                      if (selectedAddress!.districtName != null &&
                          selectedAddress!.districtName!.isNotEmpty)
                        selectedAddress!.districtName!,
                      if (selectedAddress!.cityName != null &&
                          selectedAddress!.cityName!.isNotEmpty)
                        selectedAddress!.cityName!,
                      if (selectedAddress!.provinceName != null &&
                          selectedAddress!.provinceName!.isNotEmpty)
                        selectedAddress!.provinceName!,
                      if (selectedAddress!.postalCode != null &&
                          selectedAddress!.postalCode!.isNotEmpty)
                        selectedAddress!.postalCode!,
                    ].join(', '),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // PRODUCT SUMMARY
          _buildSectionTitle('Pesanan Anda'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomNetworkImage(
                          item.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Varian: ${item.size}, ${item.color}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyUtils.format(
                                    (item.discountPrice > 0)
                                        ? item.discountPrice
                                        : item.price,
                                  ),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // SHIPPING METHOD GATE
          Builder(builder: (context) {
            final bool hasAddress = selectedAddress != null;
            final bool isShippingLoading = hasAddress && shippingState.isLoading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Metode Pengiriman'),
                _buildSelectableCard(
                  isEnabled: hasAddress,
                  isHighlighted: hasAddress && selectedCourier == null,
                  icon: !hasAddress ? Icons.lock_outline : Icons.local_shipping_outlined,
                  title: !hasAddress
                      ? 'Kurir Pengiriman (Terkunci)'
                      : (selectedCourier != null
                          ? selectedCourier!.name
                          : 'Pilih Kurir Pengiriman'),
                  subtitle: !hasAddress
                      ? 'Pilih alamat pengiriman terlebih dahulu untuk membuka kurir'
                      : (isShippingLoading
                          ? 'Sedang memuat opsi kurir & estimasi ongkir...'
                          : (selectedCourier != null
                              ? 'Estimasi tiba ${selectedCourier!.etd} hari'
                              : 'Alamat aktif! Klik untuk memilih kurir & set ongkir')),
                  trailing: isShippingLoading
                      ? 'Memuat...'
                      : (selectedCourier != null
                          ? CurrencyUtils.format(shippingCost)
                          : (hasAddress ? 'Pilih' : 'Terkunci')),
                  onTap: () {
                    if (!hasAddress) {
                      toastification.show(
                        context: context,
                        title: const Text('Silakan pilih alamat terlebih dahulu untuk membuka kurir & set ongkir'),
                        type: ToastificationType.warning,
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                      return;
                    }
                    if (isShippingLoading) {
                      toastification.show(
                        context: context,
                        title: const Text('Sedang mengambil data kurir & ongkir, mohon tunggu sebentar...'),
                        type: ToastificationType.info,
                        autoCloseDuration: const Duration(seconds: 2),
                      );
                      return;
                    }
                    _showCourierModal(context, shippingState);
                  },
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // VOUCHER SECTION
          _buildSectionTitle('Voucher Zelvira'),
          _buildSelectableCard(
            icon: Icons.confirmation_number_outlined,
            title: appliedVoucher ?? 'Pilih atau masukkan kode',
            subtitle: appliedVoucher != null
                ? 'Promo berhasil dipasang'
                : 'Hemat lebih banyak dengan voucher',
            trailing: 'Lihat',
            onTap: () {
              _showVoucherModal(context, subtotal);
            },
          ),
          const SizedBox(height: 24),

          // POINTS REDEMPTION SECTION
          _buildSectionTitle('Tukarkan Poin Zelvira'),
          _buildPointsRedemptionCard(subtotal + shippingCost - discount),
          const SizedBox(height: 24),

          // PAYMENT METHOD
          _buildSectionTitle('Metode Pembayaran'),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 24),

          // ORDER SUMMARY
          _buildSectionTitle('Ringkasan Pembayaran'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Subtotal untuk Produk',
                  CurrencyUtils.format(subtotal),
                ),
                _buildSummaryRow(
                  'Subtotal Pengiriman',
                  CurrencyUtils.format(shippingCost),
                ),
                if (discount > 0)
                  _buildSummaryRow(
                    'Diskon Voucher',
                    '- ${CurrencyUtils.format(discount)}',
                    isDiscount: true,
                  ),
                if (pointsDiscount > 0)
                  _buildSummaryRow(
                    'Potongan Poin ($pointsToUse Pts)',
                    '- ${CurrencyUtils.format(pointsDiscount)}',
                    isDiscount: true,
                  ),
                const Divider(height: 24),
                _buildSummaryRow(
                  'Total Pembayaran',
                  CurrencyUtils.format(total),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyUtils.format(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Buat Pesanan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildSelectableCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
    bool isEnabled = true,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? (isHighlighted ? AppColors.primary.withValues(alpha: 0.04) : Colors.white)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: !isEnabled
                ? Colors.grey.shade200
                : (isHighlighted ? AppColors.primary : Colors.grey.shade200),
            width: isHighlighted ? 1.5 : 1.0,
          ),
          boxShadow: isEnabled && isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !isEnabled
                    ? Colors.grey.shade100
                    : (isHighlighted
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: !isEnabled
                    ? Colors.grey.shade400
                    : (isHighlighted ? AppColors.primary : Colors.grey.shade700),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: !isEnabled ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: !isEnabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                color: !isEnabled ? Colors.grey.shade400 : AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isEnabled ? Icons.chevron_right : Icons.lock_outline,
              color: !isEnabled ? Colors.grey.shade400 : Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount
                  ? Colors.red
                  : (isTotal ? AppColors.primary : Colors.black),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentResultDialog(
    BuildContext context, {
    required bool isSuccess,
    int? orderId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isCheckingAgain = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: isSuccess ? Colors.green : Colors.orange,
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? 'Pembayaran Berhasil!' : 'Belum Terkonfirmasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess
                        ? 'Terima kasih! Pembayaran pesanan Anda telah berhasil diverifikasi.'
                        : 'Sistem belum mendeteksi pembayaran lunas. Jika Anda baru saja transfer, mohon klik Cek Status Pembayaran kembali.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (!isSuccess && orderId != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isCheckingAgain
                            ? null
                            : () async {
                                setDialogState(() => isCheckingAgain = true);
                                try {
                                  final res = await ref
                                      .read(orderServiceProvider)
                                      .syncPaymentStatus(orderId);
                                  ref
                                      .read(orderProvider.notifier)
                                      .fetchOrders();
                                  final st = res?.status.toUpperCase() ?? '';
                                  final success =
                                      st == 'PAID' ||
                                      st == 'PROCESSING' ||
                                      st == 'COMPLETED';

                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                  if (mounted) {
                                    _showPaymentResultDialog(
                                      context,
                                      isSuccess: success,
                                      orderId: orderId,
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isCheckingAgain = false);
                                }
                              },
                        icon: isCheckingAgain
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                        label: Text(
                          isCheckingAgain
                              ? 'Mengecek...'
                              : 'Cek Status Pembayaran',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Lihat Pesanan Saya',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, {bool isWallet = false}) {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWallet
                  ? Icons.account_balance_wallet_rounded
                  : Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pesanan Berhasil!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              isWallet
                  ? 'Pembayaran berhasil menggunakan Zelvira Wallet. Pesanan Anda sedang diproses.'
                  : 'Selesaikan pembayaran melalui halaman Midtrans yang telah terbuka.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Lihat Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [
          Colors.pink,
          Colors.amber,
          Colors.blue,
          Colors.green,
          Colors.purple,
        ],
      ),
    ],
  ),
);
  }

  Widget _buildPointsRedemptionCard(double maxPayable) {
    final maxPts = maxPayable.floor();
    final effectivePts = _usePoints
        ? (_userPoints > maxPts ? maxPts : _userPoints)
        : 0;
    final discountAmount = effectivePts * 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _usePoints && _userPoints > 0
              ? const Color(0xFFED8F03)
              : Colors.grey.shade200,
          width: _usePoints && _userPoints > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _usePoints && _userPoints > 0
                ? const Color(0xFFED8F03).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Tukarkan Poin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFED8F03,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_userPoints Pts',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD67700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userPoints > 0
                          ? '1 Poin = ${CurrencyUtils.format(1)} potongan'
                          : 'Poin Anda saat ini 0 Pts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _usePoints && _userPoints > 0,
                activeThumbColor: const Color(0xFFED8F03),
                onChanged: _userPoints > 0
                    ? (val) {
                        setState(() {
                          _usePoints = val;
                        });
                      }
                    : null,
              ),
            ],
          ),
          if (_usePoints && effectivePts > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Poin digunakan: $effectivePts Pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                  Text(
                    '- ${CurrencyUtils.format(discountAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _buildPaymentOption(
          value: 'MIDTRANS',
          icon: Icons.credit_card_rounded,
          title: 'Transfer Online',
          subtitle: 'Transfer bank, e-Wallet, kartu kredit, dll',
        ),
        const SizedBox(height: 10),
        _buildPaymentOption(
          value: 'WALLET',
          icon: Icons.account_balance_wallet_rounded,
          title: 'Zelvira Wallet',
          subtitle: _isLoadingWallet
              ? 'Memuat saldo...'
              : 'Saldo: ${CurrencyUtils.format(_walletBalance)}',
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(
                      Icons.radio_button_checked,
                      color: AppColors.primary,
                      key: const ValueKey('checked'),
                    )
                  : Icon(
                      Icons.radio_button_off,
                      color: Colors.grey.shade400,
                      key: const ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressModal(
    BuildContext context,
    List<AddressResponse> addresses,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Alamat Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (addresses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Belum ada alamat')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isSelected = selectedAddress?.id == addr.id;
                      return ListTile(
                        onTap: () {
                          setState(() {
                            selectedAddress = addr;
                            selectedCourier =
                                null; // Reset courier when address changes
                          });
                          // Use districtId for RajaOngkir (subdistrictId returns empty results)
                          final destId = addr.districtId ?? addr.subdistrictId;
                          ref
                              .read(shippingProvider.notifier)
                              .calculateCost(destId);
                          Navigator.pop(context);
                        },
                        title: Row(
                          children: [
                            Text(
                              addr.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (addr.isDefault)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Utama',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${addr.recipientName} | ${addr.phoneNumber}'),
                            Text(
                              addr.addressLine,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCourierModal(
    BuildContext context,
    AsyncValue<List<ShippingCourierResponse>> shippingState,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Kurir Pengiriman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              shippingState.when(
                data: (couriers) {
                  if (couriers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Kurir tidak tersedia untuk area ini'),
                      ),
                    );
                  }
                  return Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: couriers.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final courier = couriers[index];
                        final isSelected =
                            selectedCourier?.code == courier.code &&
                            selectedCourier?.service == courier.service;
                        return ListTile(
                          onTap: () {
                            setState(() {
                              selectedCourier = courier;
                            });
                            Navigator.pop(context);
                          },
                          leading: Icon(
                            Icons.local_shipping,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(
                            courier.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Estimasi ${courier.etd} hari\n${courier.description}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            'Rp ${courier.cost.toInt()}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoucherModal(BuildContext context, double currentSubtotal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Voucher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<VoucherModel>>(
                  future: _voucherService.getAvailableVouchers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final vouchers = snapshot.data ?? [];
                    if (vouchers.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada voucher tersedia'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: vouchers.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final voucher = vouchers[index];
                        final isSelected = appliedVoucher == voucher.code;
                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                appliedVoucher = null;
                                discount = 0;
                              } else {
                                appliedVoucher = voucher.code;
                                discount = _calculateVoucherDiscount(
                                  voucher,
                                  currentSubtotal,
                                );
                              }
                            });
                            Navigator.pop(context);
                          },
                          leading: Icon(
                            Icons.confirmation_number,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(
                            voucher.code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            voucher.discountType.toUpperCase() == 'PERCENTAGE'
                                ? 'Diskon ${voucher.discountAmount.toInt()}% \nMin. belanja Rp ${voucher.minPurchase.toInt()}'
                                : 'Diskon Rp ${voucher.discountAmount.toInt()} \nMin. belanja Rp ${voucher.minPurchase.toInt()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : const Text('Gunakan'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
