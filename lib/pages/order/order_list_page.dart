import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_style.dart';
import '../../riverpod/order_provider.dart';
import '../../models/checkout_model.dart';
import '../../config/url_utils.dart';
import 'package:intl/intl.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  String selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(orderProvider.notifier).fetchOrders();
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

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'MENUNGGU PEMBAYARAN';
      case 'PAID':
      case 'PROCESSING':
      case 'DIKEMAS':
        return 'DIKEMAS';
      case 'DELIVERING':
      case 'SHIPPED':
      case 'DIKIRIM':
        return 'DIKIRIM';
      case 'COMPLETED':
      case 'SELESAI':
      case 'SUCCESS':
        return 'SELESAI';
      case 'CANCELLED':
      case 'DIBATALKAN':
        return 'DIBATALKAN';
      case 'FAILED':
        return 'GAGAL';
      case 'EXPIRED':
        return 'KADALUARSA';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH BAR IN ORDERS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari pesanan anda...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Status Tabs
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTab('Semua'),
                _buildTab('PENDING'),
                _buildTab('DIKEMAS'),
                _buildTab('DIKIRIM'),
                _buildTab('SELESAI'),
              ],
            ),
          ),

          Expanded(
            child: orderState.when(
              data: (orders) {
                // Apply Search Filtering
                var filtered = orders.where((o) {
                  bool matchesQuery =
                      _searchQuery.isEmpty ||
                      o.orderNumber.toLowerCase().contains(_searchQuery) ||
                      o.items.any(
                        (item) => item.productName.toLowerCase().contains(
                          _searchQuery,
                        ),
                      );

                  bool matchesTab = false;
                  final statusUpper = o.status.toUpperCase();
                  if (selectedFilter == 'Semua') {
                    matchesTab = true;
                  } else if (selectedFilter == 'PENDING') {
                    matchesTab = statusUpper == 'PENDING';
                  } else if (selectedFilter == 'DIKEMAS') {
                    matchesTab =
                        statusUpper == 'DIKEMAS' ||
                        statusUpper == 'PAID' ||
                        statusUpper == 'PROCESSING';
                  } else if (selectedFilter == 'DIKIRIM') {
                    matchesTab =
                        statusUpper == 'DIKIRIM' ||
                        statusUpper == 'DELIVERING' ||
                        statusUpper == 'SHIPPED';
                  } else if (selectedFilter == 'SELESAI') {
                    matchesTab =
                        statusUpper == 'SELESAI' || statusUpper == 'COMPLETED';
                  } else {
                    matchesTab = statusUpper == selectedFilter.toUpperCase();
                  }

                  return matchesQuery && matchesTab;
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/lottie/empty.json',
                                width: 250,
                                height: 250,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada pesanan nih',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ayo cari produk favoritmu dan buat pesanan pertama!',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
                );
              },
              loading: () => _buildSkeletonLoading(),
              error: (err, _) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: ListView(
                  children: [
                    const SizedBox(height: 200),
                    Center(child: Text("Error: $err")),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: Colors.pink,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 140,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 110,
              height: 12,
              color: Colors.grey.shade300,
            ),
            const Divider(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 12,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 10,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 90,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                Container(
                  width: 90,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderResponse order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);

    // Format Date
    String dateStr = order.createdAt ?? '';
    try {
      if (dateStr.isNotEmpty) {
        DateTime dt = DateTime.parse(dateStr);
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (e) {
      // fallback
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                          color: Colors.pink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusLabel(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: firstItem != null
                      ? CustomNetworkImage(
                          UrlUtils.formatImageUrl(firstItem.imageUrl),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem?.productName ?? 'Produk tidak diketahui',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItems produk',
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pesanan',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      'Rp ${order.totalAmount.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (order.status.toUpperCase() == 'PENDING') ...[
                      ElevatedButton(
                        onPressed: () {
                          context.push('/order-detail', extra: order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (order.status.toUpperCase() == 'SELESAI')
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'Beli Lagi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/order-detail', extra: order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: order.status.toUpperCase() == 'PENDING'
                            ? Colors.grey.shade100
                            : AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        'Detail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: order.status.toUpperCase() == 'PENDING'
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
