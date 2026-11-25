import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_style.dart';
import '../../config/midtrans_config.dart';
import '../../models/digital_order_model.dart';
import '../../models/digital_product_model.dart';
import '../../services/digital_order_service.dart';
import '../../services/digital_product_service.dart';

class DigitalProductListPage extends StatefulWidget {
  final String category;
  final String? title;
  final bool? isPostpaid;

  const DigitalProductListPage({
    super.key,
    required this.category,
    this.title,
    this.isPostpaid,
  });

  @override
  State<DigitalProductListPage> createState() => _DigitalProductListPageState();
}

class _DigitalProductListPageState extends State<DigitalProductListPage> {
  final _digitalProductService = DigitalProductService();
  final _digitalOrderService = DigitalOrderService();
  final _customerNoController = TextEditingController();
  final _searchController = TextEditingController();
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();

  List<DigitalProduct> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DigitalProduct? _selectedProduct;
  bool _isCheckingOut = false;
  MidtransSDK? _midtrans;

  // Selected brand filter
  String _selectedBrandFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _initMidtrans();
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
        debugPrint("Midtrans finished: status = ${result.status}");
        if (mounted &&
            (result.status == 'settlement' || result.status == 'capture')) {
          _showOrderFinishedDialog();
        }
      });
    } catch (e) {
      debugPrint("Midtrans init failed: $e");
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _digitalProductService.getProducts(
        category: widget.category,
        isPostpaid: widget.isPostpaid,
      );
      if (mounted) {
        setState(() {
          _products = products.where((p) => p.isActive).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Gagal memuat daftar produk digital');
      }
    }
  }

  @override
  void dispose() {
    _customerNoController.dispose();
    _searchController.dispose();
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Detect Operator from Phone Number
  Map<String, dynamic>? _detectOperator(String number) {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 4) return null;

    final prefix4 = clean.substring(0, 4);

    // Telkomsel
    const tsel = [
      '0811',
      '0812',
      '0813',
      '0821',
      '0822',
      '0823',
      '0852',
      '0853',
      '0851',
    ];
    if (tsel.contains(prefix4)) {
      return {
        'name': 'Telkomsel',
        'color': const Color(0xFFED0226),
        'brand': 'TELKOMSEL',
      };
    }
    // Indosat
    const isat = ['0814', '0815', '0816', '0855', '0856', '0857', '0858'];
    if (isat.contains(prefix4)) {
      return {
        'name': 'Indosat',
        'color': const Color(0xFFFFB703),
        'brand': 'INDOSAT',
      };
    }
    // XL
    const xl = ['0817', '0818', '0819', '0859', '0877', '0878'];
    if (xl.contains(prefix4)) {
      return {'name': 'XL', 'color': const Color(0xFF0056B3), 'brand': 'XL'};
    }
    // Axis
    const axis = ['0831', '0832', '0833', '0838'];
    if (axis.contains(prefix4)) {
      return {
        'name': 'Axis',
        'color': const Color(0xFF8338EC),
        'brand': 'AXIS',
      };
    }
    // Tri
    const tri = ['0895', '0896', '0897', '0898', '0899'];
    if (tri.contains(prefix4)) {
      return {
        'name': 'Tri (3)',
        'color': const Color(0xFFFF5400),
        'brand': 'TRI',
      };
    }
    // Smartfren
    const smart = [
      '0881',
      '0882',
      '0883',
      '0884',
      '0885',
      '0886',
      '0887',
      '0888',
      '0889',
    ];
    if (smart.contains(prefix4)) {
      return {
        'name': 'Smartfren',
        'color': const Color(0xFFD81159),
        'brand': 'SMARTFREN',
      };
    }

    return null;
  }

  String get _inputLabel {
    final cat = widget.category.toLowerCase();
    if (cat.contains('pulsa') || cat.contains('data')) {
      return 'Nomor HP Tujuan';
    } else if (cat.contains('pln')) {
      return widget.isPostpaid == true
          ? 'ID Pelanggan PLN'
          : 'No. Meter / ID Pelanggan PLN';
    } else if (cat.contains('game')) {
      return 'User ID / Zone ID Game';
    } else if (cat.contains('money') || cat.contains('emoney')) {
      return 'Nomor HP Akun E-Wallet';
    } else if (cat.contains('bpjs')) {
      return 'Nomor Kartu BPJS';
    } else if (cat.contains('pdam')) {
      return 'Nomor Sambungan PDAM';
    } else if (cat.contains('internet')) {
      return 'Nomor Pelanggan Internet';
    }
    return 'Nomor Pelanggan / ID Tujuan';
  }

  String get _pageTitle {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    return widget.category.toUpperCase();
  }

  bool get _hasValidInput => _customerNoController.text.trim().length >= 4;

  void _handleDirectMidtransPayment() async {
    final customerNo = _customerNoController.text.trim();
    if (customerNo.isEmpty || customerNo.length < 4) {
      AppToast.error(context, 'Silakan masukkan $_inputLabel dengan benar');
      _focusNode.requestFocus();
      return;
    }

    if (_selectedProduct == null) {
      AppToast.error(context, 'Pilih paket/nominal produk terlebih dahulu');
      return;
    }

    // Modal bottom sheet to confirm email for invoice delivery
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flash_on_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Pembelian',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Pembayaran langsung melalui Midtrans',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Nomor Tujuan', customerNo, isBold: true),
                      const Divider(height: 16),
                      _buildDetailRow('Produk', _selectedProduct!.productName),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Total Bayar',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(
                          _selectedProduct!.sellingPrice > 0
                              ? _selectedProduct!.sellingPrice
                              : _selectedProduct!.price,
                        ),
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kirim Invoice ke Email:',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'nama@email.com (untuk bukti & invoice)',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _executeOrderCreation();
                    },
                    child: Text(
                      'Bayar Sekarang (Buka Midtrans)',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 13,
              fontWeight: (isBold || isHighlight)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isHighlight ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _executeOrderCreation() async {
    setState(() => _isCheckingOut = true);
    try {
      final customerNo = _customerNoController.text.trim();
      final email = _emailController.text.trim();

      final request = DigitalOrderRequest(
        skuCode: _selectedProduct!.buyerSkuCode,
        customerNo: customerNo,
        email: email.isNotEmpty ? email : null,
      );

      final order = await _digitalOrderService.createDigitalOrder(request);

      if (!mounted) return;
      setState(() => _isCheckingOut = false);

      // Directly open Midtrans
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
        } catch (e) {
          debugPrint("Failed to start midtrans ui flow: $e");
          sdkLaunched = false;
        }
      }

      if (!sdkLaunched && snapUrl.isNotEmpty) {
        final uri = Uri.parse(snapUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      }

      _showOrderPendingDialog(order.orderNumber);
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingOut = false);
        AppToast.error(
          context,
          'Gagal membuat pesanan: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  void _showOrderPendingDialog(String orderNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Pesanan Dibuat',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No. Transaksi: #$orderNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              'Silakan selesaikan pembayaran di jendela Midtrans. Setelah pembayaran berhasil, pulsa/kuota akan langsung masuk dan invoice resmi dikirimkan ke email Anda.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOrderFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Pembayaran Berhasil!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Pembayaran Anda telah diterima oleh Midtrans. Sistem sedang mengeksekusi pesanan ke provider dan bukti invoice telah dikirimkan ke email Anda.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Kembali', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final operatorInfo = _detectOperator(_customerNoController.text);

    // Filter products by search query and detected brand
    final filtered = _products.where((p) {
      // Search text filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match =
            p.productName.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            (p.desc ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }

      // Brand tab filter
      if (_selectedBrandFilter != 'Semua') {
        if (!p.brand.toLowerCase().contains(
          _selectedBrandFilter.toLowerCase(),
        )) {
          return false;
        }
      } else if (operatorInfo != null) {
        // Auto filter to detected operator if on 'Semua' and operator is detected
        final detectedBrand = (operatorInfo['brand'] as String).toLowerCase();
        if (p.brand.toLowerCase().contains(detectedBrand) ||
            p.productName.toLowerCase().contains(detectedBrand)) {
          return true;
        }
      }

      return true;
    }).toList();

    // Sort products by price ascending
    filtered.sort((a, b) {
      final priceA = a.sellingPrice > 0 ? a.sellingPrice : a.price;
      final priceB = b.sellingPrice > 0 ? b.sellingPrice : b.price;
      return priceA.compareTo(priceB);
    });

    // Extract unique brands for filter tabs
    final availableBrands = [
      'Semua',
      ..._products.map((p) => p.brand).toSet().where((b) => b.isNotEmpty),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ================= STEP 1: INPUT NOMOR / ID TUJUAN =================
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _inputLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (operatorInfo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (operatorInfo['color'] as Color)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (operatorInfo['color'] as Color)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: operatorInfo['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  operatorInfo['name'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: operatorInfo['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasValidInput
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _customerNoController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 08123456789 / 14012345678',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            widget.category.toLowerCase().contains('pln')
                                ? Icons.bolt_rounded
                                : widget.category.toLowerCase().contains('game')
                                ? Icons.sports_esports_rounded
                                : Icons.phone_android_rounded,
                            color: _hasValidInput
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),
                          suffixIcon: _customerNoController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _customerNoController.clear();
                                    setState(() {
                                      _selectedProduct = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),

                    // ================= STEP 2: SEARCH & FILTER TABS (Only shown once input >= 4 digits) =================
                    if (_hasValidInput) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari nominal, kuota, atau masa aktif...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val.trim());
                          },
                        ),
                      ),

                      // Brand Chips if multiple brands available
                      if (availableBrands.length > 2) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableBrands.map((brand) {
                              final isSelected = _selectedBrandFilter == brand;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(brand),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(
                                        () => _selectedBrandFilter = brand,
                                      );
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

              // ================= STEP 3: CONTENT / PRODUCT LIST =================
              Expanded(
                child: !_hasValidInput
                    // GUIDE ILLUSTRATION WHEN NO NUMBER IS INPUTTED YET
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.dialpad_rounded,
                                  size: 56,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Masukkan Nomor / ID Tujuan',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Silakan masukkan nomor tujuan atau ID pelanggan di atas untuk menampilkan pilihan paket & nominal yang tersedia.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada produk yang sesuai',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba kata kunci lain atau pilih filter berbeda',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          _selectedProduct != null ? 100 : 20,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final isSelected =
                              _selectedProduct?.buyerSkuCode ==
                              product.buyerSkuCode;
                          final priceToDisplay = product.sellingPrice > 0
                              ? product.sellingPrice
                              : product.price;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProduct = product;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Radio / Checkbox Indicator
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.productName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (product.desc != null &&
                                            product.desc!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            product.desc!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'id',
                                            symbol: 'Rp ',
                                            decimalDigits: 0,
                                          ).format(priceToDisplay),
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ================= STEP 4: BOTTOM BAR TO DIRECT MIDTRANS CHECKOUT =================
          if (_selectedProduct != null && _hasValidInput)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(
                                _selectedProduct!.sellingPrice > 0
                                    ? _selectedProduct!.sellingPrice
                                    : _selectedProduct!.price,
                              ),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isCheckingOut
                            ? null
                            : _handleDirectMidtransPayment,
                        child: _isCheckingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.flash_on_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Beli Sekarang',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
