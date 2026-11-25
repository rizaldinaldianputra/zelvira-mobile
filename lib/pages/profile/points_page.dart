import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final WalletService _walletService = WalletService();
  late Future<WalletResponse> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _walletService.getWalletInfo();
  }

  Future<void> _refreshPoints() async {
    setState(() {
      _walletFuture = _walletService.getWalletInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text(
          'Zelvira Points',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPoints,
        child: FutureBuilder<WalletResponse>(
          future: _walletFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        height: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      const SizedBox(height: 32),
                      for (int i = 0; i < 5; i++)
                        Container(
                          height: 70,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text('Gagal memuat point: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPoints,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Data tidak ditemukan'));
            }

            final wallet = snapshot.data!;

            // Filter only points transactions
            final pointsTransactions = wallet.recentTransactions.where((tx) {
              return tx.type == 'POINTS_EARNED' || tx.type == 'POINTS_REDEEMED';
            }).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildPointsCard(context, wallet.points),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Riwayat Point',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pointsTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat point',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...pointsTransactions.map(
                      (tx) => _buildTransactionItem(tx),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, int points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Total Point Saya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$points Pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Icon(Icons.stars_rounded, size: 80, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    bool isCredit = tx.type == 'POINTS_EARNED';

    IconData iconData = Icons.stars;
    Color iconColor = isCredit ? Colors.green : Colors.red;
    Color bgColor = (isCredit ? Colors.green : Colors.red).withValues(
      alpha: 0.1,
    );

    String amountText = '${isCredit ? '+' : '-'}${tx.points} Pts';
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(tx.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tx.status == 'SUCCESS'
                      ? Colors.green
                      : (tx.status == 'FAILED' ? Colors.red : Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
