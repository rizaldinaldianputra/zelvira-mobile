import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/digital_product_model.dart';
import '../../models/digital_order_model.dart';
import '../../services/digital_order_service.dart';
import '../../services/wallet_service.dart';
import 'package:dio/dio.dart';
import 'package:confetti/confetti.dart';

class DigitalCheckoutPage extends StatefulWidget {
  final DigitalProduct product;
  final String customerNo;

  const DigitalCheckoutPage({
    super.key,
    required this.product,
    required this.customerNo,
  });

  @override
  State<DigitalCheckoutPage> createState() => _DigitalCheckoutPageState();
}

class _DigitalCheckoutPageState extends State<DigitalCheckoutPage> {
  final _digitalOrderService = DigitalOrderService();
  final _walletService = WalletService();
  late ConfettiController _confettiController;

  bool _isProcessing = false;
  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;

  bool get _isPrepaid => widget.product.isPrepaid;

  // Postpaid state
  bool _inquiryDone = false;
  String? _postpaidCustomerName;
  double? _postpaidAmount;
  double? _postpaidAdmin;
  String? _postpaidRefId;
  String? _postpaidFormattedDesc;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _loadWallet();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final info = await _walletService.getWalletInfo();
      if (mounted) {
        setState(() {
          _walletBalance = info.balance;
          _isLoadingWallet = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  double get _currentPriceToPay {
    if (_isPrepaid) {
      return widget.product.sellingPrice > 0
          ? widget.product.sellingPrice
          : widget.product.price;
    }
    return _postpaidAmount ?? 0.0;
  }

  bool get _hasSufficientBalance {
    if (!_isPrepaid && !_inquiryDone) return true;
    return _walletBalance >= _currentPriceToPay;
  }

  Future<void> _processAction() async {
    // Check wallet balance
    if (_isPrepaid || _inquiryDone) {
      if (!_hasSufficientBalance) {
        _showErrorDialog(
          'Saldo wallet tidak mencukupi untuk melakukan pembayaran ini. Silakan top up terlebih dahulu.',
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_isPrepaid) {
        final request = DigitalOrderRequest(
          skuCode: widget.product.buyerSkuCode,
          customerNo: widget.customerNo,
        );
        final response = await _digitalOrderService.processPrepaidOrder(
          request,
        );

        if (response.data.status == 'Sukses' ||
            response.data.status == 'Pending') {
          _showSuccessDialog(response.data);
        } else {
          _showErrorDialog(
            response.data.message.isNotEmpty
                ? response.data.message
                : 'Transaksi gagal diproses',
          );
        }
      } else {
        if (!_inquiryDone) {
          // Do Inquiry
          final request = DigitalOrderRequest(
            skuCode: widget.product.buyerSkuCode,
            customerNo: widget.customerNo,
          );
          final response = await _digitalOrderService.processPostpaidInquiry(
            request,
          );
          if (!mounted) return;

          if (response.data.status == 'Sukses' ||
              response.data.status == 'Pending') {
            final data = response.data;
            setState(() {
              _inquiryDone = true;
              _postpaidCustomerName = data.customerName;
              _postpaidAmount = data.totalAmountToPay;
              _postpaidAdmin = data.admin;
              _postpaidRefId = data.refId;
              _postpaidFormattedDesc = data.formattedDesc;
            });
          } else {
            _showErrorDialog(
              response.data.message.isNotEmpty
                  ? response.data.message
                  : 'Inquiry tagihan gagal',
            );
          }
        } else {
          // Do Pay
          if (_postpaidRefId == null || _postpaidAmount == null) {
            _showErrorDialog(
              'Data tagihan tidak lengkap. Silakan lakukan cek tagihan ulang.',
            );
            return;
          }
          final response = await _digitalOrderService.processPostpaidPay(
            widget.product.buyerSkuCode,
            widget.customerNo,
            _postpaidAmount!,
            _postpaidRefId!,
          );

          if (response.data.status == 'Sukses' ||
              response.data.status == 'Pending') {
            _showSuccessDialog(response.data);
          } else {
            _showErrorDialog(
              response.data.message.isNotEmpty
                  ? response.data.message
                  : 'Pembayaran tagihan gagal',
            );
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan saat memproses pesanan.';
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          final Map data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          }
        }
      } else {
        errorMessage = e.toString();
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog(DigiflazzTransactionResponse data) {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Pesanan Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.message.isNotEmpty
                  ? data.message
                  : 'Pesanan Anda sedang diproses oleh sistem.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (data.sn.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SN / Token / Kode Voucher:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      data.sn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (data.status.toLowerCase() == 'sukses' ||
                            data.status.toLowerCase() == 'success')
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color:
                          (data.status.toLowerCase() == 'sukses' ||
                              data.status.toLowerCase() == 'success')
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (data.refId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ref ID: ${data.refId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ke Beranda',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
          Colors.orange,
        ],
      ),
    ],
  ),
);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Transaksi Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceToDisplay = _currentPriceToPay;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isPrepaid ? 'Konfirmasi Pembelian' : 'Cek & Bayar Tagihan',
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Information Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isPrepaid
                                ? Colors.blue.shade50
                                : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isPrepaid ? 'Prabayar' : 'Pascabayar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isPrepaid ? Colors.blue : Colors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.product.brand.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.desc != null &&
                        widget.product.desc!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.product.desc!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nomor Tujuan / ID:',
                          style: TextStyle(color: Colors.black54),
                        ),
                        SelectableText(
                          widget.customerNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Postpaid details if Inquiry Done
            if (!_isPrepaid && _inquiryDone) ...[
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                color: Colors.blue.shade50.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rincian Tagihan Pelanggan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(height: 16),
                      if (_postpaidCustomerName != null) ...[
                        _buildRowDetail(
                          'Nama Pelanggan',
                          _postpaidCustomerName!,
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (_postpaidFormattedDesc != null) ...[
                        _buildRowDetail('Detail Info', _postpaidFormattedDesc!),
                        const SizedBox(height: 6),
                      ],
                      if (_postpaidAdmin != null && _postpaidAdmin! > 0) ...[
                        _buildRowDetail(
                          'Biaya Admin',
                          'Rp ${_postpaidAdmin!.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 6),
                      ],
                      _buildRowDetail(
                        'Total Tagihan',
                        'Rp ${_postpaidAmount!.toStringAsFixed(0)}',
                        isBold: true,
                        valueColor: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Source / Wallet Card
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.deepOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Zelvira Wallet',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              _isLoadingWallet
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Saldo: Rp ${_walletBalance.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _hasSufficientBalance
                                            ? Colors.grey.shade700
                                            : Colors.red,
                                        fontWeight: _hasSufficientBalance
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/wallet'),
                          child: const Text('Top Up'),
                        ),
                      ],
                    ),
                    if ((_isPrepaid || _inquiryDone) &&
                        !_hasSufficientBalance) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Saldo wallet Anda kurang. Silakan top up untuk melanjutkan.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Summary
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isPrepaid
                              ? 'Rp ${priceToDisplay.toStringAsFixed(0)}'
                              : (_inquiryDone
                                    ? 'Rp ${priceToDisplay.toStringAsFixed(0)}'
                                    : 'Menunggu Cek Tagihan'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: (_isPrepaid || _inquiryDone)
                                ? Colors.deepOrange
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isPrepaid
                          ? 'Bayar Sekarang'
                          : (_inquiryDone
                                ? 'Bayar Tagihan Sekarang'
                                : 'Cek Tagihan'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
