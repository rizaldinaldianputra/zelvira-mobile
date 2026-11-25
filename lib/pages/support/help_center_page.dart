import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../services/support_service.dart';
import '../../config/app_style.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final SupportService _supportService = SupportService();
  bool _isLoading = true;
  List<dynamic> _helpItems = [];

  @override
  void initState() {
    super.initState();
    _fetchHelpItems();
  }

  Future<void> _fetchHelpItems() async {
    try {
      final items = await _supportService.getHelpArticles();
      if (!mounted) return;
      setState(() {
        _helpItems = items.isNotEmpty ? items : _defaultHelpArticles();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _helpItems = _defaultHelpArticles();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _defaultHelpArticles() {
    return [
      {
        'title': 'Panduan Pemesanan & Pembelian',
        'subtitle': 'Langkah mudah memesan produk busana pilihan Anda dari katalog hingga selesai checkout.',
        'content': '''
        <p>Berbelanja busana dan perlengkapan di Zelvira sangat mudah dan cepat:</p>
        <ol>
          <li>Jelajahi koleksi di beranda atau gunakan fitur pencarian untuk menemukan model yang Anda inginkan.</li>
          <li>Pilih varian warna dan ukuran (S, M, L, XL, XXL) yang sesuai dengan panduan size chart kami.</li>
          <li>Klik <strong>Tambah ke Keranjang</strong> atau <strong>Beli Sekarang</strong> untuk langsung menuju pembayaran.</li>
          <li>Pastikan alamat pengiriman sudah lengkap dan pilih kurir ekspedisi yang diinginkan.</li>
          <li>Pilih metode pembayaran (QRIS, VA Bank, Transfer) lalu lakukan konfirmasi.</li>
        </ol>
        <p>Status pesanan Anda dapat dipantau setiap saat di halaman <strong>Pesanan Saya</strong>.</p>
        ''',
      },
      {
        'title': 'Metode Pembayaran & Verifikasi',
        'subtitle': 'Informasi lengkap opsi pembayaran otomatis tanpa perlu unggah bukti transfer manual.',
        'content': '''
        <p>Zelvira mendukung pembayaran otomatis yang terverifikasi dalam hitungan detik:</p>
        <ul>
          <li><strong>QRIS Instan:</strong> Scan QR code menggunakan aplikasi mobile banking apa saja atau e-wallet (GoPay, OVO, Dana, ShopeePay).</li>
          <li><strong>Virtual Account (VA):</strong> Pembayaran melalui nomor rekening virtual unik BCA, Mandiri, BNI, BRI yang diverifikasi otomatis 24/7.</li>
          <li><strong>Transfer Manual:</strong> Verifikasi otomatis melalui integrasi sistem perbankan terpercaya.</li>
        </ul>
        <p>Setelah pembayaran berhasil, status pesanan otomatis berganti menjadi <strong>DIKEMAS</strong>.</p>
        ''',
      },
      {
        'title': 'Pengiriman & Pelacakan Resi',
        'subtitle': 'Ketahui jadwal pengiriman, ekspedisi kurir resmi, dan estimasi waktu paket sampai di tangan Anda.',
        'content': '''
        <p>Kami bekerja sama dengan mitra kurir terpercaya di seluruh Indonesia:</p>
        <ul>
          <li><strong>Jadwal Operasional Pengiriman:</strong> Senin hingga Sabtu (pukul 09.00 - 17.00 WIB). Pesanan terverifikasi sebelum 15.00 WIB dikirim di hari yang sama.</li>
          <li><strong>Nomor Resi:</strong> Otomatis tersedia di rincian pesanan segera setelah paket diserahkan ke pihak ekspedisi.</li>
          <li><strong>Fitur Lacak Langsung:</strong> Klik tombol <strong>Lacak Pengiriman</strong> pada kartu pesanan Anda untuk melihat lokasi kurir secara real-time.</li>
        </ul>
        ''',
      },
      {
        'title': 'Garansi Pengembalian & Penukaran',
        'subtitle': 'Syarat dan panduan penukaran ukuran atau retur barang yang cacat/salah kirim.',
        'content': '''
        <p>Kepuasan Anda adalah prioritas Zelvira. Kami menyediakan fasilitas tukar ukuran & retur:</p>
        <ul>
          <li><strong>Masa Garansi:</strong> Maksimal 7 hari sejak status paket diterima.</li>
          <li><strong>Kondisi Barang:</strong> Belum pernah dicuci, label hangtag masih menempel rapi, dan kemasan utuh.</li>
          <li><strong>Salah Kirim atau Cacat Pabrik:</strong> 100% ongkos kirim penukaran ditanggung sepenuhnya oleh Zelvira.</li>
        </ul>
        <p>Untuk mengajukan retur, buka menu <strong>Chat Support</strong> dan tim kami akan segera membantu prosesnya.</p>
        ''',
      },
      {
        'title': 'Voucher, Diskon, & Poin Reward',
        'subtitle': 'Maksimalkan penghematan belanja Anda dengan memanfaatkan kode promo dan voucher eksklusif.',
        'content': '''
        <p>Dapatkan berbagai keuntungan belanja hemat di Zelvira:</p>
        <ul>
          <li><strong>Voucher Pengguna Baru:</strong> Potongan spesial untuk pembelian pertama Anda.</li>
          <li><strong>Flash Sale & Diskon Musiman:</strong> Promo harga terbaik setiap periode hari besar.</li>
          <li><strong>Gratis Ongkir:</strong> Klaim voucher subsidi ongkir di halaman promo aplikasi.</li>
        </ul>
        <p>Klaim voucher Anda di menu Akun > Voucher Saya sebelum melakukan checkout.</p>
        ''',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Bantuan & Panduan',
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
              itemCount: _helpItems.length,
              itemBuilder: (context, index) {
                final item = _helpItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showArticle(context, item),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['subtitle'] ??
                                      'Klik untuk membaca panduan lengkap selengkapnya.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  // Not truncated with 1 line, showing full details
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showArticle(BuildContext context, dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              item['title'] ?? 'Panduan',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['subtitle'] != null &&
                    item['subtitle'].toString().trim().isNotEmpty) ...[
                  Text(
                    item['subtitle'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                HtmlWidget(
                  item['content'] ?? '<p>Konten panduan sedang disiapkan.</p>',
                  textStyle: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
