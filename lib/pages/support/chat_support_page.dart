import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:dio/dio.dart';
import 'package:zelvira/config/api_url.dart';
import 'package:zelvira/services/session_service.dart';
import 'package:zelvira/models/user_model.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:zelvira/services/product_service.dart';
import 'package:zelvira/services/order_service.dart';
import 'package:zelvira/pages/order/order_detail_page.dart';
import 'package:zelvira/pages/product/product_detail_page.dart';
import 'package:zelvira/models/product_model.dart';
import 'package:zelvira/config/currency_utils.dart';

class _ExtractedProduct {
  final String title;
  final String slug;
  final String? price;
  final String? category;
  final String? stock;
  final String? imageUrl;

  _ExtractedProduct(
    this.title,
    this.slug, {
    this.price,
    this.category,
    this.stock,
    this.imageUrl,
  });
}

class _ExtractedCards {
  final String cleanedText;
  final List<_ExtractedProduct> products;
  final List<String> orders;
  final List<String> vouchers;

  _ExtractedCards({
    required this.cleanedText,
    required this.products,
    required this.orders,
    required this.vouchers,
  });

  factory _ExtractedCards.fromText(String text) {
    final products = <_ExtractedProduct>[];
    final orders = <String>[];
    final vouchers = <String>[];

    if (text.isEmpty) {
      return _ExtractedCards(
        cleanedText: text,
        products: products,
        orders: orders,
        vouchers: vouchers,
      );
    }

    final normalized = text.replaceAll('\r\n', '\n');

    // 1. Structured product block regex:
    // e.g. • **[Krem](https://zelvira.my.id/products/krem)** — Rp 150.000
    //      Kategori: Kerudung | Stok: 10 | Gambar: https://...
    final productBlockRegex = RegExp(
      r'(?:^[ \t]*[•\*\-\d\.]+[ \t]*)?\**\[(.*?)\]\((?:https?:\/\/[^\/\s\)]+)?\/products?\/([a-zA-Z0-9_\-]+)\/?\)\**([^\n]*(?:\n[ \t]*(?:Kategori|Stok|Gambar|Stock|Category|Harga|Price)[^\n]+)*)',
      multiLine: true,
      caseSensitive: false,
    );

    final blocksToRemove = <String>[];
    for (final match in productBlockRegex.allMatches(normalized)) {
      final fullBlock = match.group(0) ?? '';
      final title = (match.group(1) ?? 'Produk').trim();
      final slug = (match.group(2) ?? '').trim();

      // Extract price
      final priceMatch = RegExp(r'(?:Rp\.?\s*[\d\.,]+)', caseSensitive: false).firstMatch(fullBlock);
      final price = priceMatch?.group(0)?.trim();

      // Extract category
      final catMatch = RegExp(r'(?:Kategori|Category):[ \t]*([^|\n\)]+)', caseSensitive: false).firstMatch(fullBlock);
      final category = catMatch?.group(1)?.trim();

      // Extract stock
      final stockMatch = RegExp(r'(?:Stok|Stock):[ \t]*([^|\n\)]+)', caseSensitive: false).firstMatch(fullBlock);
      final stock = stockMatch?.group(1)?.trim();

      // Extract image
      final imgMatch = RegExp(r'(?:Gambar|Image):[ \t]*([^\s\n\)]+)', caseSensitive: false).firstMatch(fullBlock);
      final imageUrl = imgMatch?.group(1)?.trim();

      if (slug.isNotEmpty && !products.any((p) => p.slug == slug)) {
        products.add(_ExtractedProduct(
          title,
          slug,
          price: price,
          category: category,
          stock: stock,
          imageUrl: imageUrl,
        ));
      }
      blocksToRemove.add(fullBlock);
    }

    // Clean text by removing raw product blocks
    var cleaned = normalized;
    for (final b in blocksToRemove) {
      cleaned = cleaned.replaceAll(b, '');
    }

    // Fallback 1: markdown links not caught by block regex
    final mdProductRegex = RegExp(
      r'\[(.*?)\]\((?:https?:\/\/[^\/\s\)]+)?\/products?\/([a-zA-Z0-9_\-]+)\/?\)',
      caseSensitive: false,
    );
    for (final match in mdProductRegex.allMatches(cleaned)) {
      final title = (match.group(1) ?? 'Produk').trim();
      final slug = (match.group(2) ?? '').trim();
      if (slug.isNotEmpty && !products.any((p) => p.slug == slug)) {
        products.add(_ExtractedProduct(title, slug));
      }
    }

    // Fallback 2: bare product URLs (e.g. https://zelvira.my.id/products/krem)
    final bareProductRegex = RegExp(
      r'(?:https?:\/\/[^\/\s\)]+)\/products?\/([a-zA-Z0-9_\-]+)\/?',
      caseSensitive: false,
    );
    for (final match in bareProductRegex.allMatches(cleaned)) {
      final slug = (match.group(1) ?? '').trim();
      if (slug.isNotEmpty && !products.any((p) => p.slug == slug)) {
        final rawName = slug.replaceAll('-', ' ');
        final title = rawName.isNotEmpty ? rawName[0].toUpperCase() + rawName.substring(1) : 'Produk';
        products.add(_ExtractedProduct(title, slug));
      }
    }

    cleaned = cleaned
        .replaceAll(RegExp(r'\|[\s-:]+\|'), '')
        .replaceAll('|', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // 2. Order number (ORD-...)
    final orderRegex = RegExp(r'\b(ORD-[A-Za-z0-9\-]+)\b', caseSensitive: false);
    for (final match in orderRegex.allMatches(cleaned)) {
      final orderNo = match.group(1) ?? '';
      if (orderNo.isNotEmpty && !orders.contains(orderNo)) {
        orders.add(orderNo);
      }
    }

    // 3. Voucher codes (ONLY genuine codes with digits or explicit 'Kode Voucher:' format, never common words)
    final ignoreWords = {
      'ZELVIRA', 'PROMO', 'DISKON', 'HEMAT', 'ONGKIR', 'FLASH',
      'VOUCHER', 'KODE', 'KUPON', 'GRATIS', 'ORDER', 'CHAT', 'ADMIN',
      'STORE', 'OFFICIAL', 'ASSISTANT', 'BARU', 'HARI'
    };

    // Pattern A: Explicit label e.g. "Kode Voucher: DISKON10" or "Voucher: HEMAT20"
    final explicitVoucherRegex = RegExp(
      r'(?:kode\s*(?:voucher|promo|kupon)|voucher|promo\s*code)[:\s]+[`\*]*([A-Z0-9_\-]{4,20})[`\*]*',
      caseSensitive: false,
    );
    for (final match in explicitVoucherRegex.allMatches(cleaned)) {
      final code = (match.group(1) ?? '').toUpperCase().trim();
      if (code.isNotEmpty && !ignoreWords.contains(code) && !vouchers.contains(code)) {
        vouchers.add(code);
      }
    }

    // Pattern B: Backtick code containing letters AND numbers, e.g. `DISKON10`, `HEMAT50`
    final backtickCodeRegex = RegExp(r'`([A-Z0-9_\-]{4,20})`');
    for (final match in backtickCodeRegex.allMatches(cleaned)) {
      final code = (match.group(1) ?? '').toUpperCase().trim();
      final hasDigit = RegExp(r'[0-9]').hasMatch(code);
      if (hasDigit && !ignoreWords.contains(code) && !vouchers.contains(code)) {
        vouchers.add(code);
      }
    }

    // Pattern C: Promo prefix strictly followed by digits e.g. DISKON10, HEMAT20, ZELVIRA50 (must contain digits!)
    final prefixWithDigitsRegex = RegExp(
      r'\b((?:ZELVIRA|DISKON|HEMAT|PROMO|ONGKIR|FLASH)[0-9]+[A-Z0-9]*)\b',
      caseSensitive: false,
    );
    for (final match in prefixWithDigitsRegex.allMatches(cleaned)) {
      final code = (match.group(1) ?? '').toUpperCase().trim();
      if (!ignoreWords.contains(code) && !vouchers.contains(code)) {
        vouchers.add(code);
      }
    }

    return _ExtractedCards(
      cleanedText: cleaned,
      products: products,
      orders: orders,
      vouchers: vouchers,
    );
  }
}

class ChatSupportPage extends StatefulWidget {
  const ChatSupportPage({super.key});

  @override
  State<ChatSupportPage> createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  UserModel? _currentUser;
  String _roomId = 'general';
  String _chatMode = 'AI'; // 'AI' or 'LIVE_CS'
  StompClient? _stompClient;

  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isUploading = false;
  bool _isAiTyping = false;
  final Map<String, Product?> _productDetailCache = {};

  void _fetchProductIfNeeded(String slug) {
    if (_productDetailCache.containsKey(slug)) return;
    _productDetailCache[slug] = null;
    ProductService().getProductBySlug(slug).then((prod) {
      if (mounted && prod != null) {
        setState(() {
          _productDetailCache[slug] = prod;
        });
      }
    }).catchError((_) {});
  }
  File? _selectedImage;

  // Anti-Spam state
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  // Client-side spam detection (max 5 msgs per 5 sec)
  final List<DateTime> _sentTimestamps = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = await SessionService().getUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _roomId = 'user_${user.id}';
        });
      }
    }

    await _fetchHistory();
    _connectWebSocket();
  }

  String get _wsUrl {
    // Convert baseUrl to ws protocol and target /ws-chat-native
    if (baseUrl.startsWith('https://')) {
      return '${baseUrl.replaceFirst('https://', 'wss://')}/ws-chat-native';
    } else {
      return '${baseUrl.replaceFirst('http://', 'ws://')}/ws-chat-native';
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await Dio().get('$baseUrl/api/v1/chat/$_roomId/history');
      debugPrint('[_fetchHistory] Response for $_roomId: ${response.data}');

      if (response.data != null) {
        List<dynamic> list = [];
        if (response.data is Map && response.data['data'] is List) {
          list = response.data['data'];
        } else if (response.data is List) {
          list = response.data;
        }

        if (mounted) {
          setState(() {
            _messages = list.map((item) {
              final senderRole = (item['senderRole'] ?? '').toString().toUpperCase();
              final isMe = senderRole != 'AI' &&
                  senderRole != 'ADMIN' &&
                  senderRole != 'CS' &&
                  senderRole != 'SYSTEM';
              return {
                'id': item['id'],
                'text': item['content'] ?? '',
                'senderId': item['senderId'] ?? '',
                'senderRole': senderRole,
                'attachmentUrl': item['attachmentUrl'],
                'isMe': isMe,
                'type': 'CHAT',
                'time': item['createdAt'] != null
                    ? DateTime.tryParse(item['createdAt']) ?? DateTime.now()
                    : DateTime.now(),
              };
            }).toList();

            for (int i = _messages.length - 1; i >= 0; i--) {
              final r = _messages[i]['senderRole'];
              if (r == 'ADMIN' || r == 'CS') {
                _chatMode = 'LIVE_CS';
                break;
              } else if (r == 'AI') {
                _chatMode = 'AI';
                break;
              }
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  void _connectWebSocket() {
    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: _wsUrl,
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) {
            debugPrint('Chat WebSocket error: $error');
            if (mounted) {
              setState(() => _isConnected = false);
            }
          },
          onDisconnect: (frame) {
            if (mounted) {
              setState(() => _isConnected = false);
            }
          },
        ),
      );
      _stompClient!.activate();
    } catch (e) {
      debugPrint('Stomp init error: $e');
    }
  }

  void _onConnect(StompFrame frame) {
    if (!mounted) return;
    setState(() => _isConnected = true);

    _stompClient!.subscribe(
      destination: '/topic/room/$_roomId',
      callback: (StompFrame msgFrame) {
        if (msgFrame.body == null || !mounted) return;
        try {
          final data = json.decode(msgFrame.body!);
          final type = data['type'] ?? 'CHAT';

          if (type == 'ERROR_COOLDOWN') {
            final seconds = (data['retryAfterSeconds'] ?? 15) as int;
            _startCooldown(seconds);
            if (mounted) setState(() => _isAiTyping = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['content'] ?? 'Spam terdeteksi! Silakan tunggu.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          if (type == 'TYPING') {
            if (mounted) {
              setState(() => _isAiTyping = true);
              _scrollToBottom();
            }
            return;
          }

          if (type == 'JOIN') return;

          final senderRole = (data['senderRole'] ?? '').toString().toUpperCase();
          final isMe = senderRole != 'AI' &&
              senderRole != 'ADMIN' &&
              senderRole != 'CS' &&
              senderRole != 'SYSTEM';

          if (senderRole == 'AI' || senderRole == 'ADMIN' || senderRole == 'CS') {
            _isAiTyping = false;
          }

          if (senderRole == 'ADMIN' || senderRole == 'CS') {
            _chatMode = 'LIVE_CS';
          } else if (senderRole == 'AI') {
            _chatMode = 'AI';
          }
          if (data['chatMode'] != null) {
            _chatMode = data['chatMode'].toString().toUpperCase() == 'LIVE_CS'
                ? 'LIVE_CS'
                : 'AI';
          }

          setState(() {
            _isAiTyping = false;
            _messages.add({
              'text': data['content'] ?? '',
              'senderId': data['senderId'] ?? '',
              'senderRole': senderRole,
              'attachmentUrl': data['attachmentUrl'],
              'isMe': isMe,
              'type': type,
              'time': DateTime.now(),
            });
          });
          _scrollToBottom();
        } catch (e) {
          debugPrint('Error parsing incoming chat: $e');
        }
      },
    );

    // Announce Join
    final myId = _currentUser != null ? _currentUser!.id.toString() : 'guest';
    _stompClient!.send(
      destination: '/app/chat/$_roomId/addUser',
      body: json.encode({
        'roomId': _roomId,
        'senderId': myId,
        'senderRole': 'CUSTOMER',
        'type': 'JOIN',
      }),
    );
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownRemaining = seconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() {
          _cooldownRemaining = 0;
        });
      } else {
        setState(() {
          _cooldownRemaining--;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(File file) async {
    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last.split('\\').last,
        ),
      });

      final response = await Dio().post(
        '$baseUrl/api/v1/upload',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
    return null;
  }

  void _sendMessage() async {
    if (_cooldownRemaining > 0) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // Client-side rate-check (max 5 messages in 5s)
    final now = DateTime.now();
    _sentTimestamps.removeWhere((ts) => now.difference(ts).inSeconds > 5);
    _sentTimestamps.add(now);
    if (_sentTimestamps.length > 5) {
      _startCooldown(15);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda mengirim terlalu cepat! Tunggu beberapa detik.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? attachmentUrl;
    if (_selectedImage != null) {
      final fileToUpload = _selectedImage!;
      setState(() => _selectedImage = null);
      attachmentUrl = await _uploadImage(fileToUpload);
      if (attachmentUrl == null && text.isEmpty) {
        return; // Upload failed and no text
      }
    }
    if (!mounted) return;

    final myId = _currentUser != null ? _currentUser!.id.toString() : 'guest';

    if (_stompClient != null && _isConnected) {
      setState(() => _isAiTyping = true);
      _stompClient!.send(
        destination: '/app/chat/$_roomId/sendMessage',
        body: json.encode({
          'roomId': _roomId,
          'senderId': myId,
          'senderRole': 'CUSTOMER',
          'content': text,
          'attachmentUrl': attachmentUrl,
          'type': 'CHAT',
        }),
      );
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _openProduct(String title, String slug) async {
    try {
      final cached = _productDetailCache[slug];
      if (cached != null) {
        final imgList = (cached.images != null && cached.images!.isNotEmpty)
            ? cached.images!
            : [if (cached.imageUrl != null) cached.imageUrl!];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: cached,
              images: imgList.isNotEmpty ? imgList : [''],
              title: cached.name,
              brand: 'Zelvira',
              price: cached.discountPrice ?? cached.price,
              originalPrice: cached.discountPrice != null ? cached.price : null,
              rating: cached.averageRating ?? 0.0,
              description: cached.description,
              stock: cached.totalStock,
              soldCount: 45,
            ),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
      final product = await ProductService().getProductBySlug(slug);
      if (mounted) Navigator.pop(context);
      if (product != null && mounted) {
        _productDetailCache[slug] = product;
        final imgList = (product.images != null && product.images!.isNotEmpty)
            ? product.images!
            : [if (product.imageUrl != null) product.imageUrl!];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              images: imgList.isNotEmpty ? imgList : [''],
              title: product.name,
              brand: 'Zelvira',
              price: product.discountPrice ?? product.price,
              originalPrice:
                  product.discountPrice != null ? product.price : null,
              rating: product.averageRating ?? 0.0,
              description: product.description,
              stock: product.totalStock,
              soldCount: 45,
            ),
          ),
        );
      } else if (mounted) {
        context.push('/search', extra: null);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      if (mounted) context.push('/search', extra: null);
    }
  }

  void _openOrder(String orderNo) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
      final order = await OrderService().getOrderByNumber(orderNo);
      if (mounted) Navigator.pop(context);
      if (order != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderData: order),
          ),
        );
      } else if (mounted) {
        context.push('/home/2');
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      if (mounted) context.push('/home/2');
    }
  }

  void _claimVoucher(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher "$code" berhasil diklaim & disalin!'),
        backgroundColor: Colors.pink.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
    context.push('/profile/vouchers');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _stompClient?.deactivate();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _chatMode == 'AI'
                    ? Colors.pink.withValues(alpha: 0.12)
                    : Colors.teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _chatMode == 'AI' ? Icons.auto_awesome : Icons.support_agent,
                color: _chatMode == 'AI' ? Colors.pink : Colors.teal.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatMode == 'AI' ? 'ZELVIRA ASSISTANT' : 'Admin Zelvira',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontFamily: 'Outfit',
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.green : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isConnected
                          ? (_chatMode == 'AI' ? 'AI Assistant • Online 24/7' : 'Live Chat Admin • Online')
                          : 'Menghubungkan...',
                      style: TextStyle(
                        color: _isConnected ? Colors.green.shade700 : Colors.amber.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Anti-spam warning banner
          if (_cooldownRemaining > 0)
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pesan dibatasi sementara (Anti-Spam). Tunggu $_cooldownRemaining detik.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _chatMode == 'AI' ? 'Mulai obrolan dengan Zelvira Assistant' : 'Mulai obrolan dengan Admin Zelvira',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isAiTyping && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(2),
                                bottomRight: Radius.circular(18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.pink,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI sedang menulis...',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      final isMe = msg['isMe'] as bool;
                      final String? attachmentUrl = msg['attachmentUrl'];
                      final String text = msg['text'] ?? '';
                      final cards = !isMe ? _ExtractedCards.fromText(text) : null;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.pink : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (attachmentUrl != null &&
                                  attachmentUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CustomNetworkImage(
                                    attachmentUrl,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      padding: const EdgeInsets.all(8),
                                      child: const Text('Gagal memuat gambar'),
                                    ),
                                  ),
                                ),
                              if (attachmentUrl != null && (cards != null ? cards.cleanedText.isNotEmpty : text.isNotEmpty))
                                const SizedBox(height: 8),
                              if ((cards != null ? cards.cleanedText.isNotEmpty : text.isNotEmpty))
                                Text(
                                  cards != null ? cards.cleanedText : text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Outfit',
                                  ),
                                ),

                              // Full Product Cards (Photo, Category, Stock, Price & Lihat button)
                              if (cards != null && cards.products.isNotEmpty) ...[
                                if (cards.cleanedText.isNotEmpty) const SizedBox(height: 10),
                                ...cards.products.map(
                                  (p) {
                                    final cached = _productDetailCache[p.slug];
                                    final effectiveImage = (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                        ? p.imageUrl!
                                        : (cached?.imageUrl ??
                                            (cached?.images != null && cached!.images!.isNotEmpty
                                                ? cached.images!.first
                                                : ''));
                                    final effectivePrice = (p.price != null && p.price!.isNotEmpty)
                                        ? p.price!
                                        : (cached != null
                                            ? CurrencyUtils.format(
                                                cached.discountPrice != null && cached.discountPrice! > 0
                                                    ? cached.discountPrice!
                                                    : cached.price)
                                            : '');
                                    final effectiveCategory = (p.category != null && p.category!.isNotEmpty)
                                        ? p.category!
                                        : (cached?.category?.name ?? '');
                                    final effectiveStock = (p.stock != null && p.stock!.isNotEmpty)
                                        ? p.stock!
                                        : (cached != null ? '${cached.totalStock}' : '');

                                    if (effectiveImage.isEmpty && !_productDetailCache.containsKey(p.slug)) {
                                      _fetchProductIfNeeded(p.slug);
                                    }

                                    return Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        onTap: () => _openProduct(p.title, p.slug),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.pink.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                        children: [
                                          // FOTO PRODUK
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              width: 64,
                                              height: 64,
                                              color: Colors.grey.shade100,
                                              child: effectiveImage.isNotEmpty
                                                  ? CustomNetworkImage(
                                                      effectiveImage,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => const Icon(
                                                        Icons.shopping_bag_outlined,
                                                        color: Colors.pink,
                                                        size: 26,
                                                      ),
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.shopping_bag_outlined,
                                                        color: Colors.pink,
                                                        size: 26,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // DETAIL PRODUK (Judul, Kategori, Stok, Harga)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (effectiveCategory.isNotEmpty)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                        margin: const EdgeInsets.only(right: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.pink.shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          effectiveCategory,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.pink.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                    if (effectiveStock.isNotEmpty)
                                                      Text(
                                                        'Stok: $effectiveStock',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey.shade600,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  p.title,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                if (effectivePrice.isNotEmpty)
                                                  Text(
                                                    effectivePrice,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.pink,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),

                                          // TOMBOL LIHAT
                                          ElevatedButton(
                                            onPressed: () => _openProduct(p.title, p.slug),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.pink,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: const Size(0, 32),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text(
                                                  'Lihat',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(width: 2),
                                                Icon(Icons.arrow_forward_ios_rounded, size: 10),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                              ],
                              const SizedBox(height: 4),

                              // Order Cards
                              if (cards != null && cards.orders.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ...cards.orders.map(
                                  (orderNo) => InkWell(
                                    onTap: () => _openOrder(orderNo),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.indigo.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.indigo,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.local_shipping_outlined,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'PESANAN SAYA',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo,
                                                  ),
                                                ),
                                                Text(
                                                  orderNo,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: Colors.indigo,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Voucher Cards
                              if (cards != null && cards.vouchers.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ...cards.vouchers.map(
                                  (code) => InkWell(
                                    onTap: () => _claimVoucher(code),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.confirmation_number_outlined,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                code,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[100],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'PROMO',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 28,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[700],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () => _claimVoucher(code),
                                            icon: const Icon(Icons.copy, size: 12),
                                            label: const Text(
                                              'Klaim & Salin Voucher',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Foto siap dikirim',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          if (_isUploading)
            const LinearProgressIndicator(
              color: Colors.pink,
              backgroundColor: Colors.white,
            ),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_camera_back_outlined,
                    color: Colors.pink,
                  ),
                  onPressed: _cooldownRemaining > 0 ? null : _pickImage,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      enabled: _cooldownRemaining == 0,
                      decoration: InputDecoration(
                        hintText: _cooldownRemaining > 0
                            ? 'Menunggu cooldown ($_cooldownRemaining dtk)...'
                            : 'Ketik pesan...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cooldownRemaining > 0 ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cooldownRemaining > 0 ? Colors.grey : Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
