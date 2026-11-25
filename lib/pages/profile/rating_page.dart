import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../models/checkout_model.dart';
import '../../config/app_style.dart';
import '../../components/button_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final OrderService _orderService = OrderService();
  final ReviewService _reviewService = ReviewService();

  bool _isLoading = true;
  List<OrderItemResponse> _itemsToRate = [];

  @override
  void initState() {
    super.initState();
    _fetchItemsToRate();
  }

  Future<void> _fetchItemsToRate() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getMyOrders();
      final completedOrders = orders
          .where((o) => o.status == 'COMPLETED' || o.status == 'SELESAI')
          .toList();

      List<OrderItemResponse> toRate = [];
      for (var order in completedOrders) {
        for (var item in order.items) {
          if (!item.isRated) {
            toRate.add(item);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _itemsToRate = toRate;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRatingDialog(OrderItemResponse item) {
    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nilai Produk',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
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
                            fontFamily: 'Outfit',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.size.isNotEmpty || item.color.isNotEmpty)
                          Text(
                            '${item.size} ${item.color}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (val) {
                    rating = val;
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan Anda...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Kirim Penilaian',
                color: AppColors.primary,
                onPressed: () async {
                  Navigator.pop(context);
                  _submitRating(item, rating.toInt(), commentController.text);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRating(
    OrderItemResponse item,
    int rating,
    String comment,
  ) async {
    setState(() => _isLoading = true);
    try {
      final req = ReviewRequest(
        productId: item.productId,
        rating: rating,
        comment: comment,
        userName: 'User', // Normally get from profile
        orderItemId: item.id,
      );
      await _reviewService.submitReview(req);
      await _fetchItemsToRate(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penilaian berhasil dikirim!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim penilaian: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Beri Penilaian',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _itemsToRate.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pesanan yang perlu dinilai',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itemsToRate.length,
      itemBuilder: (context, index) {
        final item = _itemsToRate[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
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
                        fontSize: 16,
                        fontFamily: 'Outfit',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.size} ${item.color}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _showRatingDialog(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Nilai',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
