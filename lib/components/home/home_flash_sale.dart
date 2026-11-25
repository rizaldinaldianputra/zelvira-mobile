import 'dart:async' as java_timer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../riverpod/home_provider.dart';
import '../card_widget.dart';
import '../../models/product_model.dart';
import '../../models/content_section_model.dart';

class HomeFlashSale extends ConsumerWidget {
  const HomeFlashSale({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashSaleAsync = ref.watch(homeFlashSaleContentProvider);

    return flashSaleAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        // Collect ALL products from ALL flash sale items
        final List<Map<String, dynamic>> displayProducts = [];

        // Find campaign dates if any
        DateTime? campaignEndDate;
        final campaignWithDate = items.firstWhere(
          (i) => i.endDate != null,
          orElse: () => items.first,
        );
        campaignEndDate = campaignWithDate.endDate;

        for (var item in items) {
          // 1. Check for bulk products in item
          if (item.products != null && item.products!.isNotEmpty) {
            for (var p in item.products!) {
              displayProducts.add({'product': p, 'item': item});
            }
          }
          // 2. Check for single product in item
          if (item.product != null) {
            displayProducts.add({'product': item.product, 'item': item});
          }
        }

        if (displayProducts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FLASH SALE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (campaignWithDate.title != null)
                          Text(
                            campaignWithDate.title!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (campaignEndDate != null)
                    _FlashSaleTimer(endDate: campaignEndDate),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                  final data = displayProducts[index];
                  final product = data['product'] as Product;
                  final item = data['item'] as ContentItem;

                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    child: ProductCard(
                      image: product.imageUrl ?? item.imageUrl ?? '',
                      title: product.name,
                      brand: 'Zelvira',
                      price: product.price,
                      originalPrice: product.discountPrice,
                      rating: product.rating,
                      product: product,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => _buildShimmerCards(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmerCards() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.65),
            highlightColor: Colors.white,
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
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
    );
  }
}

class _FlashSaleTimer extends StatefulWidget {
  final DateTime endDate;
  const _FlashSaleTimer({required this.endDate});

  @override
  State<_FlashSaleTimer> createState() => _FlashSaleTimerState();
}

class _FlashSaleTimerState extends State<_FlashSaleTimer> {
  late Duration _timeLeft;
  late java_timer.Timer _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.endDate.difference(DateTime.now());
    _timer = java_timer.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = widget.endDate.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) return const SizedBox.shrink();

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Row(
      children: [
        _timerBox(hours),
        const Text(
          ":",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        _timerBox(minutes),
        const Text(
          ":",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        _timerBox(seconds),
      ],
    );
  }

  Widget _timerBox(String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
