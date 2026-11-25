import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../config/midtrans_config.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zelvira/config/app_style.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletService _walletService = WalletService();
  late Future<WalletResponse> _walletFuture;
  MidtransSDK? _midtrans;
  int? _lastTopupTransactionId; // saved so we can verify after payment

  @override
  void initState() {
    super.initState();
    _walletFuture = _walletService.getWalletInfo();
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
        debugPrint("Midtrans Finished callback: status = ${result.status}");
        // Verify with backend regardless of Midtrans SDK status,
        // because the SDK result is not always reliable on mobile.
        _verifyAndRefreshWallet();
      });
    } catch (e) {
      debugPrint("Failed to initialize Midtrans SDK: $e");
    }
  }

  /// After payment window closes, ask backend to check Midtrans status
  /// and credit the balance if payment was successful.
  Future<void> _verifyAndRefreshWallet() async {
    final txId = _lastTopupTransactionId;
    if (txId == null) {
      _refreshWallet();
      return;
    }
    try {
      final result = await _walletService.verifyTopup(txId);
      final status = result['status']?.toString() ?? '';
      final message = result['message']?.toString() ?? '';
      if (mounted) {
        if (status == 'SUCCESS') {
          AppToast.success(
            context,
            message.isNotEmpty ? message : 'Top-up berhasil!',
          );
        } else if (status == 'FAILED') {
          AppToast.error(
            context,
            message.isNotEmpty ? message : 'Pembayaran gagal.',
          );
        }
        _refreshWallet();
      }
    } catch (e) {
      debugPrint('Verify topup error: $e');
      if (mounted) _refreshWallet();
    }
  }

  Future<void> _refreshWallet() async {
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
          'Zelvira Pay',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWallet,
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
                        height: 200,
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
                    Text('Gagal memuat wallet: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshWallet,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Data tidak ditemukan'));
            }

            final wallet = snapshot.data!;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildWalletCard(context, wallet),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (wallet.recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...wallet.recentTransactions.map(
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

  Widget _buildWalletCard(BuildContext context, WalletResponse wallet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4F9A), Color(0xFFE91E63), Color(0xFFC2185B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zelvira Pay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Digital Wallet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Rp ${wallet.balance.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context.push('/point'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Points',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${wallet.points}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 35,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    _showTopupDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: Color(0xFFE91E63),
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Top Up',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    bool isCredit = tx.type == 'TOPUP' || tx.type == 'REFUND';
    bool isPoints = tx.type == 'POINTS_EARNED' || tx.type == 'POINTS_REDEEMED';

    IconData iconData = Icons.receipt_long;
    Color iconColor = Colors.blue;
    Color bgColor = Colors.blue.withValues(alpha: 0.1);

    if (tx.type == 'TOPUP') {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (tx.type == 'PAYMENT') {
      iconData = Icons.shopping_bag;
      iconColor = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.1);
    } else if (isPoints) {
      iconData = Icons.stars;
      iconColor = Colors.amber;
      bgColor = Colors.amber.withValues(alpha: 0.1);
    } else if (tx.type == 'REFUND') {
      iconData = Icons.refresh;
      iconColor = Colors.teal;
      bgColor = Colors.teal.withValues(alpha: 0.1);
    }

    String amountText;
    if (isPoints) {
      amountText = '${isCredit ? '+' : '-'}${tx.points} Pts';
    } else {
      amountText = '${isCredit ? '+' : '-'}Rp ${tx.amount.toStringAsFixed(0)}';
    }

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    final isPendingTopup = tx.status == 'PENDING' && tx.type == 'TOPUP';

    Widget content = Container(
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
                  color: isCredit ? Colors.green : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  String label = tx.status;
                  Color color = Colors.orange;

                  if (tx.status == 'SUCCESS') {
                    label = 'SUCCESS';
                    color = Colors.green;
                  } else if (tx.status == 'EXPIRED') {
                    label = 'EXPIRED';
                    color = Colors.grey[700]!;
                  } else if (tx.status == 'PENDING') {
                    label = 'WAITING';
                    color = Colors.orange[800]!;
                  } else if (tx.status == 'FAILED') {
                    label = 'FAILED';
                    color = Colors.red;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );

    if (isPendingTopup) {
      return GestureDetector(onTap: () => _resumeTopup(tx), child: content);
    }
    return content;
  }

  Future<void> _resumeTopup(WalletTransaction tx) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _walletService.resumeTopup(tx.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response['token'] != null) {
        _lastTopupTransactionId = tx.id;
        final token = response['token'].toString();
        final snapUrl = AppMidtransConfig.resolvePaymentUrl(
          paymentUrl: response['redirect_url'] ?? response['paymentUrl'],
          paymentToken: token,
        );

        bool sdkLaunched = false;
        if (_midtrans != null) {
          try {
            await _midtrans?.startPaymentUiFlow(token: token);
            sdkLaunched = true;
          } catch (e) {
            debugPrint("Failed startPaymentUiFlow: $e");
            sdkLaunched = false;
          }
        }
        if (!sdkLaunched && snapUrl.isNotEmpty) {
          final uri = Uri.parse(snapUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
          }
        }
      } else {
        throw 'Token pembayaran tidak ditemukan';
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error
        AppToast.error(context, e.toString());
      }
    }
  }

  void _showTopupDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    bool isLoading = false;
    bool isValidAmount = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Up Saldo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final amount = double.tryParse(val) ?? 0;
                      setModalState(() {
                        isValidAmount = amount >= 10000;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Nominal Top Up',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValidAmount
                            ? const Color(0xFFE91E63)
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (!isValidAmount || isLoading)
                          ? null
                          : () async {
                              final text = amountController.text;
                              if (text.isEmpty) return;
                              final amount = double.tryParse(text);
                              if (amount == null || amount < 10000) {
                                AppToast.error(
                                  context,
                                  'Minimal top up Rp 10.000',
                                );
                                return;
                              }

                              setModalState(() => isLoading = true);
                              try {
                                final response = await _walletService
                                    .initiateTopup(amount);
                                if (response['token'] != null) {
                                  // Save transaction ID for post-payment verification
                                  _lastTopupTransactionId =
                                      response['id'] as int? ??
                                      (response['transactionId'] != null
                                          ? int.tryParse(
                                              response['transactionId']
                                                  .toString(),
                                            )
                                          : null);
                                  if (mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    ); // Close modal before opening Midtrans
                                  }

                                  final token = response['token'].toString();
                                  final snapUrl =
                                      AppMidtransConfig.resolvePaymentUrl(
                                    paymentUrl: response['redirect_url'] ??
                                        response['paymentUrl'],
                                    paymentToken: token,
                                  );

                                  bool sdkLaunched = false;
                                  if (_midtrans != null) {
                                    try {
                                      await _midtrans?.startPaymentUiFlow(
                                        token: token,
                                      );
                                      sdkLaunched = true;
                                    } catch (e) {
                                      debugPrint(
                                          "Failed startPaymentUiFlow: $e");
                                      sdkLaunched = false;
                                    }
                                  }
                                  if (!sdkLaunched && snapUrl.isNotEmpty) {
                                    final uri = Uri.parse(snapUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.inAppWebView);
                                    }
                                  }
                                } else {
                                  throw 'Gagal mendapatkan token pembayaran';
                                }
                              } catch (e) {
                                AppToast.error(context, e.toString());
                              } finally {
                                setModalState(() => isLoading = false);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Lanjutkan Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
}
