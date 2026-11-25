import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../services/support_service.dart';
import '../../config/app_style.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final SupportService _supportService = SupportService();
  bool _isLoading = true;
  List<dynamic> _faqItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFAQ();
  }

  Future<void> _fetchFAQ() async {
    try {
      final items = await _supportService.getFaqs();
      if (!mounted) return;
      setState(() {
        _faqItems = items.isNotEmpty ? items : _defaultFaqs();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _faqItems = _defaultFaqs();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _defaultFaqs() {
    return [
      {
        'question': 'Bagaimana cara melakukan pemesanan di Zelvira?',
        'answer': '<p>Pilih produk gamis atau busana favorit Anda, tentukan ukuran dan warna, lalu klik <strong>+ Keranjang</strong> atau <strong>Beli Sekarang</strong>. Lanjutkan ke halaman Checkout, pilih alamat pengiriman dan metode pembayaran, lalu selesaikan pembayaran.</p>',
      },
      {
        'question': 'Metode pembayaran apa saja yang didukung?',
        'answer': '<p>Zelvira mendukung berbagai metode pembayaran aman dan instan:</p><ul><li><strong>QRIS (BCA, GoPay, OVO, Dana, ShopeePay, LinkAja)</strong></li><li><strong>Virtual Account Bank (BCA, Mandiri, BNI, BRI, Permata)</strong></li><li><strong>Kartu Kredit / Debit Online</strong></li><li><strong>Transfer Bank Manual</strong></li></ul>',
      },
      {
        'question': 'Berapa lama estimasi pengiriman pesanan saya?',
        'answer': '<p>Pesanan yang diverifikasi sebelum pukul 15.00 WIB akan diproses dan dikirim di hari yang sama:</p><ul><li><strong>Jabodetabek:</strong> 1 - 2 hari kerja.</li><li><strong>Pulau Jawa:</strong> 2 - 3 hari kerja.</li><li><strong>Luar Pulau Jawa:</strong> 3 - 5 hari kerja (tergantung ekspedisi dan lokasi).</li></ul>',
      },
      {
        'question': 'Bagaimana cara melacak posisi paket saya?',
        'answer': '<p>Buka menu <strong>Pesanan Saya</strong> di tab Profil, pilih pesanan yang sedang berstatus <strong>DIKIRIM</strong>, lalu klik <strong>Lacak Pengiriman</strong> untuk melihat update kurir secara live.</p>',
      },
      {
        'question': 'Apakah saya bisa menukar ukuran atau retur barang?',
        'answer': '<p>Ya, kami memberikan garansi retur & tukar ukuran dalam waktu <strong>7 hari</strong> setelah barang diterima dengan syarat produk belum dipakai, belum dicuci, dan label tag masih utuh. Silakan hubungi tim Customer Service kami melalui menu Chat Support.</p>',
      },
      {
        'question': 'Bagaimana cara menggunakan voucher promo atau diskon?',
        'answer': '<p>Di halaman Checkout atau Keranjang Belanja, klik kolom <strong>Gunakan Voucher</strong>, lalu pilih voucher yang tersedia atau ketik kode voucher resmi untuk mendapatkan potongan harga langsung.</p>',
      },
      {
        'question': 'Apakah produk Zelvira ready stock dan 100% original?',
        'answer': '<p>Seluruh produk yang berstatus tersedia di katalog aplikasi adalah <strong>100% Original rancangan Zelvira</strong> dengan kualitas bahan premium berstandar ekspor.</p>',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan (FAQ)',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqItems.length,
              itemBuilder: (context, index) {
                final item = _faqItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: Colors.grey.shade600,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        item['question'] ?? 'No Question',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: HtmlWidget(
                            item['answer'] ?? 'No answer provided.',
                            textStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.6,
                            ),
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
