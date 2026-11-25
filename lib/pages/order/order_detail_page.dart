// ignore_for_file: curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../config/app_style.dart';
import '../../models/checkout_model.dart';
import '../../config/url_utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zelvira/components/notifcation_widget.dart';
import '../../riverpod/shipping_provider.dart';
import '../../riverpod/order_provider.dart';
import '../../services/review_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../config/midtrans_config.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final OrderResponse orderData;

  const OrderDetailPage({super.key, required this.orderData});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _isLoadingTracking = false;
  bool _isProcessingPayment = false;
  bool _isCompletingOrder = false;
  late String _currentStatus;
  MidtransSDK? _midtrans;

  Map<String, dynamic>? _liveTrackingData;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderData.status;
    _initMidtrans();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.orderData.trackingNumber != null &&
          widget.orderData.trackingNumber!.trim().isNotEmpty) {
        _fetchTracking(_getCourierCode(), auto: true);
      }
    });
  }

  String _getCourierCode() {
    String courierCode = (widget.orderData.shippingService ?? 'jne')
        .toLowerCase();
    if (courierCode.contains('sicepat')) {
      return 'sicepat';
    } else if (courierCode.contains('jnt') || courierCode.contains('j&t')) {
      return 'jnt';
    } else if (courierCode.contains('pos')) {
      return 'pos';
    } else if (courierCode.contains('tiki')) {
      return 'tiki';
    } else if (courierCode.contains('anteraja')) {
      return 'anteraja';
    }
    return 'jne';
  }

  Future<void> _handleCompleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Pesanan Diterima',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Pastikan Anda telah menerima paket dan memeriksa produk dalam kondisi baik. Apakah pesanan sudah diterima?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, Sudah Diterima',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCompletingOrder = true);
    try {
      await ref
          .read(orderServiceProvider)
          .updateOrderStatus(widget.orderData.id, 'COMPLETED');
      if (!mounted) return;
      setState(() {
        _currentStatus = 'COMPLETED';
      });
      ref.read(orderProvider.notifier).fetchOrders();
      if (mounted) {
        AppToast.success(
          context,
          'Pesanan berhasil diselesaikan. Terima kasih!',
        );
        // Prompt rating for the first unrated item
        final unrated = widget.orderData.items
            .where((i) => !i.isRated)
            .toList();
        if (unrated.isNotEmpty) {
          _showRatingBottomSheet(unrated.first);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Gagal menyelesaikan pesanan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCompletingOrder = false);
      }
    }
  }

  void _showRatingBottomSheet(OrderItemResponse item) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Beri Nilai Produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomNetworkImage(
                          UrlUtils.formatImageUrl(item.imageUrl),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Varian: ${item.size}, ${item.color}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Bagaimana kualitas produk ini?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: RatingBar.builder(
                      initialRating: selectedRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setModalState(() {
                          selectedRating = rating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis ulasan Anda mengenai produk ini...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final comment = commentController.text.trim();
                              if (comment.isEmpty) {
                                AppToast.warning(
                                  context,
                                  'Tuliskan ulasan Anda terlebih dahulu',
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final reviewService = ReviewService();
                                await reviewService.submitReview(
                                  ReviewRequest(
                                    productId: item.productId,
                                    rating: selectedRating.toInt(),
                                    comment: comment,
                                    userName: 'Pelanggan',
                                    orderItemId: item.id,
                                  ),
                                );

                                if (mounted) {
                                  // ignore: duplicate_ignore
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(ctx);
                                  AppToast.success(
                                    context,
                                    'Terima kasih atas ulasan Anda!',
                                  );
                                  ref
                                      .read(orderProvider.notifier)
                                      .fetchOrders();
                                }
                              } catch (e) {
                                if (mounted) {
                                  AppToast.error(
                                    context,
                                    'Gagal mengirim ulasan: $e',
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kirim Ulasan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
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
      _midtrans?.setTransactionFinishedCallback((result) {
        debugPrint(
          "Midtrans Finished callback in Detail: status = ${result.status}",
        );
        ref.read(orderProvider.notifier).fetchOrders();
      });
    } catch (e) {
      debugPrint("Failed to initialize Midtrans SDK in Detail: $e");
    }
  }

  Future<void> _handlePayNow() async {
    final order = widget.orderData;
    setState(() => _isProcessingPayment = true);
    try {
      final snapUrl = AppMidtransConfig.resolvePaymentUrl(
        paymentUrl: order.paymentUrl,
        paymentToken: order.paymentToken,
      );

      bool sdkLaunched = false;
      if (_midtrans != null &&
          order.paymentToken != null &&
          order.paymentToken!.isNotEmpty) {
        try {
          await _midtrans?.startPaymentUiFlow(token: order.paymentToken!);
          sdkLaunched = true;
          return;
        } catch (e) {
          debugPrint("Failed startPaymentUiFlow: $e");
          sdkLaunched = false;
        }
      }

      // Fallback via paymentUrl or Snap URL
      if (!sdkLaunched && snapUrl.isNotEmpty) {
        final uri = Uri.parse(snapUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } else {
          if (mounted) {
            AppToast.error(context, 'Tidak dapat membuka halaman pembayaran');
          }
        }
      } else if (!sdkLaunched && snapUrl.isEmpty) {
        if (mounted) {
          AppToast.warning(context, 'Token pembayaran tidak tersedia');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ref.read(orderProvider.notifier).fetchOrders();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SELESAI':
      case 'COMPLETED':
      case 'SUCCESS':
        return Colors.green;
      case 'DIBATALKAN':
      case 'CANCELLED':
      case 'FAILED':
      case 'EXPIRED':
        return Colors.red;
      case 'DIKIRIM':
      case 'DELIVERING':
      case 'SHIPPED':
        return Colors.blue;
      case 'DIKEMAS':
      case 'PAID':
      case 'PROCESSING':
        return Colors.orange;
      case 'PENDING':
      default:
        return AppColors.primary;
    }
  }

  List<dynamic> _extractManifest(Map<String, dynamic> data) {
    if (data['manifest'] is List<dynamic>) {
      return data['manifest'] as List<dynamic>;
    }
    if (data['history'] is List<dynamic>) {
      return data['history'] as List<dynamic>;
    }
    if (data['data'] is Map<String, dynamic>) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['manifest'] is List<dynamic>)
        return inner['manifest'] as List<dynamic>;
      if (inner['history'] is List<dynamic>)
        return inner['history'] as List<dynamic>;
    }
    if (data['rajaongkir']?['result'] is Map<String, dynamic>) {
      final inner = data['rajaongkir']['result'] as Map<String, dynamic>;
      if (inner['manifest'] is List<dynamic>)
        return inner['manifest'] as List<dynamic>;
      if (inner['history'] is List<dynamic>)
        return inner['history'] as List<dynamic>;
    }
    return [];
  }

  Map<String, dynamic> _extractSummary(Map<String, dynamic> data) {
    if (data['summary'] is Map<String, dynamic>) {
      return data['summary'] as Map<String, dynamic>;
    }
    if (data['data']?['summary'] is Map<String, dynamic>) {
      return data['data']['summary'] as Map<String, dynamic>;
    }
    if (data['rajaongkir']?['result']?['summary'] is Map<String, dynamic>) {
      return data['rajaongkir']['result']['summary'] as Map<String, dynamic>;
    }
    return {};
  }

  Map<String, dynamic> _extractDeliveryStatus(Map<String, dynamic> data) {
    if (data['delivery_status'] is Map<String, dynamic>) {
      return data['delivery_status'] as Map<String, dynamic>;
    }
    if (data['data']?['delivery_status'] is Map<String, dynamic>) {
      return data['data']['delivery_status'] as Map<String, dynamic>;
    }
    if (data['rajaongkir']?['result']?['delivery_status']
        is Map<String, dynamic>) {
      return data['rajaongkir']['result']['delivery_status']
          as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> _fetchTracking(String courierCode, {bool auto = false}) async {
    final awb = widget.orderData.trackingNumber;
    if (awb == null || awb.trim().isEmpty) {
      if (!auto) AppToast.warning(context, 'Nomor resi belum tersedia');
      return;
    }

    setState(() {
      _isLoadingTracking = true;
    });

    try {
      final res = await ref
          .read(shippingServiceProvider)
          .trackWaybill(
            awb.trim(),
            courierCode,
            phone: widget.orderData.shippingPhone,
          );
      if (mounted) {
        setState(() {
          _liveTrackingData = res;
          _isLoadingTracking = false;
        });
        if (!auto) {
          _showLiveTrackingSheet(res);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTracking = false;
        });
        if (!auto) {
          AppToast.error(context, 'Gagal melacak resi: $e');
        }
      }
    }
  }

  void _showLiveTrackingSheet(Map<String, dynamic> data) {
    final manifestList = _extractManifest(data);
    final summary = _extractSummary(data);
    _extractDeliveryStatus(data);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Pengiriman (RajaOngkir)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Resi: ${widget.orderData.trackingNumber ?? "-"} (${summary["courier_name"] ?? widget.orderData.shippingService ?? "-"})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          summary['status'] ?? widget.orderData.status,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: manifestList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Riwayat pelacakan belum tersedia dari pihak ekspedisi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: manifestList.length,
                            itemBuilder: (context, idx) {
                              final item = manifestList[idx];
                              final desc =
                                  item['manifest_description'] ??
                                  item['desc'] ??
                                  '';
                              final date =
                                  item['manifest_date'] ?? item['date'] ?? '';
                              final time =
                                  item['manifest_time'] ?? item['time'] ?? '';
                              final city = item['city_name'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: idx == 0
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        if (idx != manifestList.length - 1)
                                          Container(
                                            width: 2,
                                            height: 40,
                                            color: Colors.grey.shade200,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            desc,
                                            style: TextStyle(
                                              fontWeight: idx == 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$date $time ${city.isNotEmpty ? "• $city" : ""}',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                            ),
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInvoiceDialog() {
    final order = widget.orderData;
    String dateStr = order.createdAt ?? '';
    try {
      if (dateStr.isNotEmpty) {
        DateTime dt = DateTime.parse(dateStr);
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Bukti Transaksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Zelvira Official Store',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              _buildDetailRow('No. Invoice / Pesanan', order.orderNumber),
              _buildDetailRow('Waktu Transaksi', dateStr),
              _buildDetailRow('Metode Pembayaran', 'Midtrans / Online'),
              const Divider(height: 24),

              const Text(
                'Rincian Pembelian:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} (x${item.quantity})',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rp ${(item.price * item.quantity).toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Rp ${order.totalAmount.toInt()}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Bagikan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'INVOICE ZELIXA\nNo. Pesanan: ${order.orderNumber}\nTotal: Rp ${order.totalAmount.toInt()}\nStatus: ${order.status}\nTerima kasih telah berbelanja di Zelvira!',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Simpan Bukti',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        AppToast.success(
                          context,
                          'Bukti transaksi berhasil disimpan!',
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderData;
    bool isCancelled = orderData.status.toUpperCase() == 'DIBATALKAN';
    bool isDigital =
        orderData.shippingService == null ||
        orderData.shippingService!.isEmpty ||
        orderData.shippingService!.toLowerCase() == 'digital' ||
        orderData.shippingService!.toLowerCase() == 'none' ||
        orderData.shippingService!.toLowerCase() == 'null' ||
        (orderData.shippingAmount == 0 &&
            orderData.shippingService!.toLowerCase() == 'free');

    String dateStr = orderData.createdAt ?? '';
    try {
      if (dateStr.isNotEmpty) {
        DateTime dt = DateTime.parse(dateStr);
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    String courierCode = (orderData.shippingService ?? 'jne').toLowerCase();
    if (courierCode.contains('sicepat')) {
      courierCode = 'sicepat';
    } else if (courierCode.contains('jnt') || courierCode.contains('j&t')) {
      courierCode = 'jnt';
    } else if (courierCode.contains('pos')) {
      courierCode = 'pos';
    } else if (courierCode.contains('tiki')) {
      courierCode = 'tiki';
    } else if (courierCode.contains('anteraja')) {
      courierCode = 'anteraja';
    } else {
      courierCode = 'jne';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: () {
        final status = _currentStatus.toUpperCase();

        if (status == 'PENDING') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessingPayment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    _isProcessingPayment
                        ? 'Membuka Pembayaran...'
                        : 'Bayar Sekarang (Rp ${orderData.totalAmount.toInt()})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _isProcessingPayment ? null : _handlePayNow,
                ),
              ),
            ),
          );
        }

        if (status == 'DELIVERING' ||
            status == 'SHIPPED' ||
            status == 'DIKIRIM') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isCompletingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isCompletingOrder
                        ? 'Menyelesaikan Pesanan...'
                        : 'Pesanan Telah Diterima',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _isCompletingOrder ? null : _handleCompleteOrder,
                ),
              ),
            ),
          );
        }

        return null;
      }(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PENDING PAYMENT BANNER WITH EXPIRATION
            if (orderData.status.toUpperCase() == 'PENDING') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.amber.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.orange.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menunggu Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selesaikan pembayaran sebelum batas waktu agar pesanan tidak dibatalkan otomatis.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Batas Waktu Pembayaran (24 Jam)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  () {
                                    try {
                                      if (orderData.createdAt != null &&
                                          orderData.createdAt!.isNotEmpty) {
                                        DateTime dt = DateTime.parse(
                                          orderData.createdAt!,
                                        ).add(const Duration(hours: 24));
                                        return DateFormat(
                                          'dd MMMM yyyy, HH:mm WIB',
                                        ).format(dt);
                                      }
                                    } catch (_) {}
                                    return '24 jam setelah pesanan dibuat';
                                  }(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ORDER INFO CARD
            _buildWhiteCard(
              child: Column(
                children: [
                  _buildDetailRow('No. Pesanan', orderData.orderNumber),
                  _buildDetailRow('Tanggal Pesanan', dateStr),
                  _buildDetailRow(
                    'Status',
                    orderData.status.toUpperCase(),
                    valueColor: _getStatusColor(orderData.status),
                  ),
                  if (isDigital) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: const Text(
                            'PRODUK DIGITAL',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text(
                            'Bukti Transaksi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _showInvoiceDialog,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Produk'),
            ...orderData.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWhiteCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomNetworkImage(
                          UrlUtils.formatImageUrl(item.imageUrl),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                          ),
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
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Varian: ${item.size}, ${item.color}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} Barang x Rp ${item.price.toInt()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (_currentStatus.toUpperCase() == 'COMPLETED' ||
                                _currentStatus.toUpperCase() == 'SELESAI') ...[
                              const SizedBox(height: 8),
                              item.isRated
                                  ? Row(
                                      children: const [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Sudah Dinilai',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        side: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.star,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        'Beri Nilai',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showRatingBottomSheet(item),
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // DIGITAL INVOICE CARD ONLY (NO SHIPPING TRACKING FOR DIGITAL)
            if (isDigital) ...[
              _buildSectionTitle('Bukti Pembelian'),
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Transaksi Produk Digital Berhasil',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Produk digital langsung dikirimkan ke akun atau nomor tujuan. Unduh invoice resmi pembelian Anda di bawah ini.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Download Invoice Bukti',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _showInvoiceDialog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // PHYSICAL SHIPPING & RAJAONGKIR TRACKING
              _buildSectionTitle('Lacak Pengiriman'),
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderData.shippingService ?? 'Kurir Pengiriman',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'No. Resi: ${orderData.trackingNumber != null && orderData.trackingNumber!.isNotEmpty ? orderData.trackingNumber : "Belum diinput"}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (orderData.trackingNumber != null &&
                                      orderData.trackingNumber!.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: orderData.trackingNumber!,
                                          ),
                                        );
                                        AppToast.success(
                                          context,
                                          'No. Resi disalin: ${orderData.trackingNumber!}',
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (orderData.trackingNumber != null &&
                            orderData.trackingNumber!.isNotEmpty)
                          ElevatedButton.icon(
                            icon: _isLoadingTracking
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
                                    size: 16,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isLoadingTracking ? 'Melacak...' : 'Lacak Resi',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _isLoadingTracking
                                ? null
                                : () => _fetchTracking(courierCode),
                          ),
                      ],
                    ),

                    if (orderData.trackingNumber != null &&
                        orderData.trackingNumber!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          if (_isLoadingTracking && _liveTrackingData == null) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Menghubungkan ke server ekspedisi...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (_liveTrackingData != null) {
                            final manifestList = _extractManifest(
                              _liveTrackingData!,
                            );
                            final summary = _extractSummary(_liveTrackingData!);
                            final delivery = _extractDeliveryStatus(
                              _liveTrackingData!,
                            );

                            if (manifestList.isNotEmpty) {
                              final latest = manifestList.first;
                              final desc =
                                  latest['manifest_description'] ??
                                  latest['desc'] ??
                                  '';
                              final date =
                                  latest['manifest_date'] ??
                                  latest['date'] ??
                                  '';
                              final time =
                                  latest['manifest_time'] ??
                                  latest['time'] ??
                                  '';
                              final city = latest['city_name'] ?? '';
                              final statusStr =
                                  delivery['status'] ??
                                  summary['status'] ??
                                  'ON PROCESS';

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50.withValues(
                                    alpha: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.pink.shade100,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Posisi Terkini Paket (${summary["courier_name"] ?? courierCode.toUpperCase()})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.pink.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            statusStr,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$date $time ${city.isNotEmpty ? "• $city" : ""}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _showLiveTrackingSheet(
                                        _liveTrackingData!,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Lihat Riwayat Lengkap (${manifestList.length} Checkpoint)',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 10,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 15,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Resi telah diterbitkan (${orderData.shippingService ?? "Kurir"}). Paket sedang diproses untuk penyerahan ke kurir. Pergerakan posisi paket biasanya muncul setelah paket discan di counter/hub kurir.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],

                    const Divider(height: 24),
                    FixedTimeline.tileBuilder(
                      theme: TimelineThemeData(
                        nodePosition: 0,
                        indicatorTheme: const IndicatorThemeData(size: 15.0),
                        connectorTheme: const ConnectorThemeData(
                          thickness: 2.0,
                        ),
                      ),
                      builder: TimelineTileBuilder.connected(
                        indicatorBuilder: (context, index) {
                          final statusIdx = _getStatusIndex(_currentStatus);
                          final isReached = index <= statusIdx;
                          return DotIndicator(
                            color: isReached
                                ? (isCancelled ? Colors.red : AppColors.primary)
                                : Colors.grey.shade300,
                          );
                        },
                        connectorBuilder: (context, index, type) {
                          final statusIdx = _getStatusIndex(_currentStatus);
                          final isReached = index < statusIdx;
                          return SolidLineConnector(
                            color: isReached
                                ? (isCancelled ? Colors.red : AppColors.primary)
                                : Colors.grey.shade300,
                          );
                        },
                        contentsBuilder: (context, index) {
                          final statuses = _generateTimelines(orderData);
                          final isReached =
                              index <= _getStatusIndex(_currentStatus);
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              bottom: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statuses[index]['title']!,
                                  style: TextStyle(
                                    fontWeight: isReached
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                    color: isReached
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                                if (statuses[index]['subtitle'] != null &&
                                    statuses[index]['subtitle']!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    statuses[index]['subtitle']!,
                                    style: TextStyle(
                                      color: isReached
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                                if (statuses[index]['time'] != null &&
                                    statuses[index]['time']!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    statuses[index]['time']!,
                                    style: TextStyle(
                                      color: isReached
                                          ? AppColors.primary
                                          : Colors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        itemCount: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (!isDigital) ...[
              _buildSectionTitle('Alamat Pengiriman'),
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orderData.shippingRecipient != null &&
                                  orderData.shippingRecipient!.isNotEmpty
                              ? orderData.shippingRecipient!
                              : 'Alamat Penerima',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (orderData.shippingPhone != null &&
                            orderData.shippingPhone!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${orderData.shippingPhone})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        orderData.shippingAddress != null &&
                                orderData.shippingAddress!.isNotEmpty
                            ? orderData.shippingAddress!
                            : 'Alamat lengkap pengiriman terdaftar pada akun Anda',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildSectionTitle('Info Pembayaran'),
            _buildWhiteCard(
              child: Column(
                children: [
                  _buildDetailRow('Metode Pembayaran', () {
                    final method = (orderData.paymentMethod ?? 'MIDTRANS')
                        .toUpperCase();
                    if (method == 'WALLET') return 'Zelvira Wallet';
                    if (method == 'MIDTRANS') {
                      return 'Transfer Online / Midtrans';
                    }
                    return method;
                  }()),
                  _buildDetailRow(
                    'Total Harga Produk',
                    'Rp ${(orderData.totalAmount - orderData.shippingAmount).toInt()}',
                  ),
                  if (!isDigital)
                    _buildDetailRow(
                      'Biaya Ongkos Kirim',
                      'Rp ${orderData.shippingAmount.toInt()}',
                    ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${orderData.totalAmount.toInt()}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  int _getStatusIndex(String status) {
    switch (status.toUpperCase()) {
      case 'SELESAI':
      case 'COMPLETED':
      case 'SUCCESS':
        return 4;
      case 'DIKIRIM':
      case 'DELIVERING':
      case 'SHIPPED':
        return 3;
      case 'DIKEMAS':
      case 'PROCESSING':
        return 2;
      case 'DIBAYAR':
      case 'PAID':
        return 1;
      case 'PENDING':
      default:
        return 0;
    }
  }

  List<Map<String, String>> _generateTimelines(OrderResponse order) {
    final status = _currentStatus.toUpperCase();
    final bool isCancelled = status == 'DIBATALKAN' || status == 'CANCELLED';

    String createdDate = '';
    String updatedDate = '';
    try {
      if (order.createdAt != null) {
        createdDate = DateFormat(
          'dd MMM yyyy, HH:mm',
        ).format(DateTime.parse(order.createdAt!));
      }
      if (order.updatedAt != null) {
        updatedDate = DateFormat(
          'dd MMM yyyy, HH:mm',
        ).format(DateTime.parse(order.updatedAt!));
      }
    } catch (_) {}

    return [
      {
        'title': 'Pesanan Dibuat',
        'subtitle': 'Menunggu konfirmasi & pembayaran',
        'time': createdDate,
      },
      {
        'title': 'Pembayaran Berhasil',
        'subtitle': 'Pesanan telah dibayar oleh pembeli',
        'time': (status != 'PENDING' && status != 'EXPIRED') ? updatedDate : '',
      },
      {
        'title': 'Sedang Dikemas',
        'subtitle': 'Penjual sedang menyiapkan barang di gudang',
        'time':
            (status == 'PROCESSING' ||
                status == 'DELIVERING' ||
                status == 'COMPLETED' ||
                status == 'SELESAI')
            ? updatedDate
            : '',
      },
      {
        'title': 'Dalam Pengiriman',
        'subtitle':
            order.trackingNumber != null && order.trackingNumber!.isNotEmpty
            ? 'Resi: ${order.trackingNumber}'
            : 'Kurir sedang mengantar ke alamat tujuan',
        'time':
            (status == 'DELIVERING' ||
                status == 'COMPLETED' ||
                status == 'SELESAI')
            ? updatedDate
            : '',
      },
      {
        'title': isCancelled ? 'Pesanan Dibatalkan' : 'Pesanan Selesai',
        'subtitle': isCancelled
            ? 'Pesanan telah dibatalkan'
            : 'Pesanan telah diterima oleh pembeli',
        'time': (status == 'COMPLETED' || status == 'SELESAI' || isCancelled)
            ? updatedDate
            : '',
      },
    ];
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
