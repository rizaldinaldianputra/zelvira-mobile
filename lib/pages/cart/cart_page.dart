import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../config/app_style.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../riverpod/cart_provider.dart';
import '../../models/cart_model.dart';
import '../../config/url_utils.dart';
import '../../config/currency_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    await ref.read(cartProvider.notifier).fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Keranjang',
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
      body: cartState.when(
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: _buildEmptyCart(),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildCartFooter(cartItems, subtotal),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: ListView(
            children: [
              const SizedBox(height: 200),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _handleRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItemResponse item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Remove Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              ref.read(cartProvider.notifier).removeFromCart(item.id);
            },
          ),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomNetworkImage(
              UrlUtils.formatImageUrl(item.imageUrl),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Details
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
                const SizedBox(height: 4),
                Text(
                  '${item.groupName} | ${item.size}, ${item.color}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  item.stock <= 0
                      ? 'Stok Habis'
                      : (item.quantity > item.stock
                            ? 'Melebihi stok (Tersedia: ${item.stock})'
                            : 'Sisa stok: ${item.stock}'),
                  style: TextStyle(
                    color: (item.stock <= 0 || item.quantity > item.stock)
                        ? Colors.red
                        : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: (item.stock <= 0 || item.quantity > item.stock)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyUtils.format(
                            (item.discountPrice > 0)
                                ? item.discountPrice
                                : item.price,
                          ),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (item.discountPrice > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.format(item.price),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Quantity control
                    _CartItemQtyEditor(item: item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter(List<CartItemResponse> cartItems, double subtotal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Harga',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyUtils.format(subtotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: () async {
                const storage = FlutterSecureStorage();
                final token = await storage.read(key: 'auth_token');
                if (token == null || token.isEmpty) {
                  if (context.mounted) {
                    toastification.show(
                      context: context,
                      title: const Text('Silakan Login'),
                      description: const Text(
                        'Anda harus login terlebih dahulu untuk checkout.',
                      ),
                      type: ToastificationType.warning,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                    context.push('/login');
                  }
                  return;
                }
                // Check if any cart item has quantity > stock or stock <= 0
                for (final item in cartItems) {
                  if (item.stock <= 0) {
                    toastification.show(
                      context: context,
                      title: const Text('Stok Habis'),
                      description: Text(
                        'Produk "${item.productName}" sudah habis. Harap hapus dari keranjang.',
                      ),
                      type: ToastificationType.error,
                      autoCloseDuration: const Duration(seconds: 4),
                    );
                    return;
                  }
                  if (item.quantity > item.stock) {
                    toastification.show(
                      context: context,
                      title: const Text('Jumlah Melebihi Stok'),
                      description: Text(
                        'Produk "${item.productName}" dipesan ${item.quantity}, namun stok hanya tersedia ${item.stock}.',
                      ),
                      type: ToastificationType.warning,
                      autoCloseDuration: const Duration(seconds: 4),
                    );
                    return;
                  }
                }
                context.push('/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/empty.json', width: 250, height: 250),
          const SizedBox(height: 16),
          const Text(
            'Wah, keranjangmu masih kosong!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yuk, mulai belanja dan pilih produk impianmu!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CartItemQtyEditor extends ConsumerStatefulWidget {
  final CartItemResponse item;
  const _CartItemQtyEditor({required this.item});

  @override
  ConsumerState<_CartItemQtyEditor> createState() => _CartItemQtyEditorState();
}

class _CartItemQtyEditorState extends ConsumerState<_CartItemQtyEditor> {
  late TextEditingController _qtyController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _qtyController = TextEditingController(text: _quantity.toString());
  }

  @override
  void didUpdateWidget(covariant _CartItemQtyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity &&
        _quantity != widget.item.quantity) {
      _quantity = widget.item.quantity;
      if (_qtyController.text != _quantity.toString()) {
        _qtyController.text = _quantity.toString();
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _updateQty(int newQty) {
    if (newQty < 1) return;
    final maxStock = widget.item.stock;
    if (maxStock > 0 && newQty > maxStock) {
      toastification.show(
        context: context,
        title: const Text('Batas Stok'),
        description: Text('Stok hanya tersedia $maxStock'),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 2),
      );
      newQty = maxStock;
    }
    setState(() {
      _quantity = newQty;
      _qtyController.text = newQty.toString();
    });
    ref.read(cartProvider.notifier).updateQuantity(widget.item.id, newQty);
  }

  @override
  Widget build(BuildContext context) {
    final maxStock = widget.item.stock;
    final bool canIncrease = maxStock <= 0 || _quantity < maxStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (_quantity > 1) {
                _updateQty(_quantity - 1);
              } else {
                ref.read(cartProvider.notifier).removeFromCart(widget.item.id);
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 16, color: Colors.blueGrey),
            ),
          ),
          SizedBox(
            width: 36,
            child: TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                final newQty = int.tryParse(val);
                if (newQty != null && newQty > 0) {
                  _updateQty(newQty);
                }
              },
            ),
          ),
          InkWell(
            onTap: canIncrease
                ? () {
                    _updateQty(_quantity + 1);
                  }
                : () {
                    toastification.show(
                      context: context,
                      title: const Text('Batas Stok'),
                      description: Text('Stok hanya tersedia $maxStock'),
                      type: ToastificationType.warning,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.add,
                size: 16,
                color: canIncrease ? Colors.blueGrey : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
