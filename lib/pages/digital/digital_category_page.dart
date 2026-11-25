import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/wallet_service.dart';
import '../../services/digital_product_service.dart';

class DigitalCategoryPage extends StatefulWidget {
  const DigitalCategoryPage({super.key});

  @override
  State<DigitalCategoryPage> createState() => _DigitalCategoryPageState();
}

class _DigitalCategoryPageState extends State<DigitalCategoryPage> {
  final _walletService = WalletService();
  final _digitalService = DigitalProductService();

  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;
  List<DigitalCategoryItem>? _activeCategories;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadWallet(), _loadCategories()]);
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

  Future<void> _loadCategories() async {
    try {
      final cats = await _digitalService.getCategoriesList(onlyActive: true);
      if (mounted) {
        setState(() {
          _activeCategories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Produk Digital (PPOB)'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange.shade600,
                      Colors.deepOrange.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Wallet Anda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoadingWallet
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Rp ${_walletBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/wallet'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Top Up',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionHeader(
                'Prabayar (Isi Ulang)',
                Icons.bolt,
                Colors.orange,
              ),
              _buildPrepaidGrid(context),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 32),
              ),

              _buildSectionHeader(
                'Tagihan (Pascabayar)',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildPostpaidGrid(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepaidGrid(BuildContext context) {
    final allItems = [
      _CategoryData(
        title: 'Pulsa',
        category: 'pulsa',
        icon: Icons.phone_android,
        color: Colors.blue,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Paket Data',
        category: 'data',
        icon: Icons.wifi,
        color: Colors.green,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Token PLN',
        category: 'pln',
        icon: Icons.electric_bolt,
        color: Colors.amber.shade700,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'E-Money',
        category: 'emoney',
        icon: Icons.account_balance_wallet,
        color: Colors.purple,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Voucher Game',
        category: 'game',
        icon: Icons.sports_esports,
        color: Colors.redAccent,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Voucher Digital',
        category: 'voucher',
        icon: Icons.confirmation_number,
        color: Colors.teal,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Paket Telpon & SMS',
        category: 'paket',
        icon: Icons.call,
        color: Colors.indigo,
        isPostpaid: false,
      ),
      _CategoryData(
        title: 'Masa Aktif',
        category: 'masa aktif',
        icon: Icons.access_time,
        color: Colors.orange,
        isPostpaid: false,
      ),
    ];

    final items = _activeCategories == null
        ? allItems
        : _activeCategories!
            .where((c) => !c.isPostpaid && c.isActive)
            .map((c) {
              final defaultMatch = allItems.firstWhere(
                (item) => item.category.toLowerCase() == c.code.toLowerCase(),
                orElse: () => _CategoryData(
                  title: c.name,
                  category: c.code,
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                  isPostpaid: false,
                ),
              );
              Color color = defaultMatch.color;
              if (c.colorHex != null && c.colorHex!.isNotEmpty) {
                try {
                  final hex = c.colorHex!.replaceAll('#', '');
                  if (hex.length == 6) {
                    color = Color(int.parse('0xFF$hex'));
                  }
                } catch (_) {}
              }
              return _CategoryData(
                title: c.name.isNotEmpty ? c.name : defaultMatch.title,
                category: c.code,
                icon: defaultMatch.icon,
                color: color,
                isPostpaid: false,
                iconUrl: c.iconUrl,
              );
            }).toList();

    if (items.isEmpty && !_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Tidak ada layanan prabayar yang aktif saat ini.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return _buildGrid(items);
  }

  Widget _buildPostpaidGrid(BuildContext context) {
    final allItems = [
      _CategoryData(
        title: 'Tagihan PLN',
        category: 'pln',
        icon: Icons.power,
        color: Colors.amber.shade800,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'BPJS Kesehatan',
        category: 'bpjs',
        icon: Icons.health_and_safety,
        color: Colors.teal,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'PDAM Air',
        category: 'pdam',
        icon: Icons.water_drop,
        color: Colors.lightBlue,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'Internet & TV',
        category: 'internet',
        icon: Icons.router,
        color: Colors.deepPurple,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'Pascabayar HP',
        category: 'pasca',
        icon: Icons.phone_iphone,
        color: Colors.blueGrey,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'Gas PGN',
        category: 'gas',
        icon: Icons.local_fire_department,
        color: Colors.deepOrange,
        isPostpaid: true,
      ),
      _CategoryData(
        title: 'Multifinance',
        category: 'finance',
        icon: Icons.credit_card,
        color: Colors.brown,
        isPostpaid: true,
      ),
    ];

    final items = _activeCategories == null
        ? allItems
        : _activeCategories!
            .where((c) => c.isPostpaid && c.isActive)
            .map((c) {
              final defaultMatch = allItems.firstWhere(
                (item) => item.category.toLowerCase() == c.code.toLowerCase(),
                orElse: () => _CategoryData(
                  title: c.name,
                  category: c.code,
                  icon: Icons.receipt_long,
                  color: Colors.amber.shade800,
                  isPostpaid: true,
                ),
              );
              Color color = defaultMatch.color;
              if (c.colorHex != null && c.colorHex!.isNotEmpty) {
                try {
                  final hex = c.colorHex!.replaceAll('#', '');
                  if (hex.length == 6) {
                    color = Color(int.parse('0xFF$hex'));
                  }
                } catch (_) {}
              }
              return _CategoryData(
                title: c.name.isNotEmpty ? c.name : defaultMatch.title,
                category: c.code,
                icon: defaultMatch.icon,
                color: color,
                isPostpaid: true,
                iconUrl: c.iconUrl,
              );
            }).toList();

    if (items.isEmpty && !_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Tidak ada layanan pascabayar yang aktif saat ini.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return _buildGrid(items);
  }

  Widget _buildGrid(List<_CategoryData> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return _buildGridItem(context, items[index]);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, _CategoryData item) {
    return InkWell(
      onTap: () {
        context.push(
          '/digital-products?category=${item.category}&title=${Uri.encodeComponent(item.title)}&isPostpaid=${item.isPostpaid}',
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: (item.iconUrl != null && item.iconUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.network(
                        item.iconUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(item.icon, color: item.color, size: 28),
                      ),
                    ),
                  )
                : Icon(item.icon, color: item.color, size: 28),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final bool isPostpaid;

  final String? iconUrl;

  _CategoryData({
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.isPostpaid,
    this.iconUrl,
  });
}
