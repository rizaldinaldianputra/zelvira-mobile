import 'package:flutter/material.dart';
import '../../config/app_style.dart';
import '../../services/review_service.dart';
import 'package:intl/intl.dart';

class ProductReviewsPage extends StatefulWidget {
  final int? productId;
  final String productTitle;
  final double initialRating;

  const ProductReviewsPage({
    super.key,
    this.productId,
    required this.productTitle,
    this.initialRating = 0.0,
  });

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allReviews = [];
  int? _selectedRatingFilter; // null = Semua, 1 - 5 = star filter

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> apiReviews = [];
      if (widget.productId != null) {
        apiReviews = await _reviewService.getProductReviews(widget.productId!);
      }
      if (mounted) {
        setState(() {
          _allReviews = apiReviews;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allReviews = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredReviews {
    if (_selectedRatingFilter == null) return _allReviews;
    return _allReviews.where((r) {
      final rating = (r['rating'] is num) ? (r['rating'] as num).round() : 5;
      return rating == _selectedRatingFilter;
    }).toList();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rate_review_outlined,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Ulasan Pembeli',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Produk "${widget.productTitle}" belum memiliki ulasan dari pembeli. Ulasan akan tampil di sini setelah pembeli memberikan ulasan.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Kembali ke Produk'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReviews;
    final totalCount = _allReviews.length;

    // Calculate rating distribution
    Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double sum = 0;
    for (var r in _allReviews) {
      final rVal = (r['rating'] is num) ? (r['rating'] as num).round() : 5;
      counts[rVal] = (counts[rVal] ?? 0) + 1;
      sum += (r['rating'] is num) ? (r['rating'] as num).toDouble() : 5.0;
    }
    final avgRating = totalCount > 0
        ? (sum / totalCount)
        : (widget.initialRating > 0 ? widget.initialRating : 0.0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ulasan Pembeli',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: _allReviews.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── RATING SUMMARY CARD ──────────────────────────────────────────
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          avgRating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (idx) => Icon(
                                              idx < avgRating.round()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$totalCount Ulasan',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        children: [5, 4, 3, 2, 1].map((star) {
                                          final count = counts[star] ?? 0;
                                          final percent = totalCount > 0
                                              ? (count / totalCount)
                                              : 0.0;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2.5,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '$star',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child:
                                                        LinearProgressIndicator(
                                                          value: percent,
                                                          minHeight: 6,
                                                          backgroundColor:
                                                              Colors
                                                                  .grey
                                                                  .shade100,
                                                          color: Colors.amber,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 20,
                                                  child: Text(
                                                    '$count',
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ─── FILTER CHIPS 1 - 5 STARS ────────────────────────────────────
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  _buildFilterChip('Semua ($totalCount)', null),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    '⭐ 5 (${counts[5] ?? 0})',
                                    5,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    '⭐ 4 (${counts[4] ?? 0})',
                                    4,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    '⭐ 3 (${counts[3] ?? 0})',
                                    3,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    '⭐ 2 (${counts[2] ?? 0})',
                                    2,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    '⭐ 1 (${counts[1] ?? 0})',
                                    1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ─── REVIEW LIST ──────────────────────────────────────────────────
                          if (filtered.isEmpty)
                            Container(
                              color: Colors.white,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 60,
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedRatingFilter != null
                                        ? 'Belum ada ulasan dengan bintang $_selectedRatingFilter'
                                        : 'Belum ada ulasan untuk produk ini',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              color: Colors.white,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildReviewTile(filtered[index]);
                                },
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int? ratingVal) {
    final isSelected = _selectedRatingFilter == ratingVal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRatingFilter = ratingVal;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final userName =
        review['userName'] ?? review['user_name'] ?? 'Pembeli Zelvira';
    final comment = review['comment'] ?? '';
    final rating = (review['rating'] is num)
        ? (review['rating'] as num).round()
        : 5;
    final variant = review['variant'] ?? '';
    final helpfulCount = review['helpfulCount'] ?? 0;

    String dateStr = '';
    if (review['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(review['createdAt'].toString());
        dateStr = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {
        dateStr = review['createdAt'].toString();
      }
    }

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'Z';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (idx) => Icon(
                            idx < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (variant.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              variant,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Membantu ($helpfulCount)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
