import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../services/support_service.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final SupportService _supportService = SupportService();
  bool _isLoading = true;
  String _htmlContent = '';
  String _title = 'Kebijakan Privasi';
  String? _updatedAt;

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    try {
      final policy = await _supportService.getPrivacyPolicy();
      if (!mounted) return;
      if (policy != null &&
          policy['content'] != null &&
          policy['content'].toString().trim().isNotEmpty) {
        setState(() {
          _title = policy['title']?.toString().isNotEmpty == true
              ? policy['title']
              : 'Kebijakan Privasi';
          _htmlContent = policy['content'];
          _updatedAt = policy['updatedAt']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _htmlContent = _defaultPrivacyPolicyHtml();
          _updatedAt = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _htmlContent = _defaultPrivacyPolicyHtml();
        _updatedAt = null;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '24 Oktober 2026';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _defaultPrivacyPolicyHtml() {
    return '''
    <div style="font-family: sans-serif; line-height: 1.6; color: #333333;">
      <h2 style="color: #111827; margin-top: 0;">Komitmen Perlindungan Privasi Zelvira</h2>
      <p>Privasi Anda adalah prioritas utama kami di <strong>Zelvira</strong>. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi data pribadi Anda saat menggunakan layanan kami.</p>
      
      <h3 style="color: #ec4899; margin-top: 24px;">1. Data yang Kami Kumpulkan</h3>
      <p>Kami mengumpulkan data yang Anda berikan secara langsung saat mendaftar atau bertransaksi:</p>
      <ul>
        <li><strong>Informasi Akun:</strong> Nama lengkap, alamat email, nomor telepon/WhatsApp, dan kata sandi terenkripsi.</li>
        <li><strong>Informasi Pengiriman:</strong> Alamat tujuan, nama penerima, kontak aktif, dan catatan khusus pengiriman.</li>
        <li><strong>Informasi Transaksi:</strong> Riwayat pembelian, metode pembayaran, invoice, dan status pesanan.</li>
      </ul>

      <h3 style="color: #ec4899; margin-top: 24px;">2. Penggunaan Informasi Pribadi</h3>
      <p>Data Anda kami gunakan semata-mata untuk kepentingan layanan pelanggan dan operasional:</p>
      <ul>
        <li>Memproses, mengemas, dan mengirimkan pesanan ke alamat tujuan Anda.</li>
        <li>Mengirimkan konfirmasi pembayaran, update nomor resi pengiriman, dan notifikasi penting.</li>
        <li>Memberikan bantuan respon cepat melalui tim Customer Support dan AI Assistant Zelvira.</li>
        <li>Menyediakan promo eksklusif, voucher diskon, dan rekomendasi produk personal yang relevan.</li>
      </ul>

      <h3 style="color: #ec4899; margin-top: 24px;">3. Kerahasiaan Data & Pihak Ketiga</h3>
      <p><strong>Zelvira tidak pernah dan tidak akan pernah menjual atau menyewakan informasi pribadi Anda kepada pihak manapun.</strong> Kami hanya membagikan data yang sangat diperlukan kepada mitra operasional resmi:</p>
      <ul>
        <li><strong>Mitra Ekspedisi Logistik:</strong> JNE, J&T, SiCepat, dll. untuk pengantaran barang ke alamat Anda.</li>
        <li><strong>Payment Gateway Berizin BI:</strong> Midtrans, Xendit, QRIS untuk pemrosesan pembayaran yang aman dan tersertifikasi PCI-DSS.</li>
      </ul>

      <h3 style="color: #ec4899; margin-top: 24px;">4. Keamanan Data</h3>
      <p>Kami menerapkan standar enkripsi SSL/TLS tingkat tinggi dan penyimpanan aman untuk melindungi data Anda dari akses tanpa izin, kebocoran, atau perubahan.</p>

      <h3 style="color: #ec4899; margin-top: 24px;">5. Hak Pengguna & Penghapusan Akun</h3>
      <p>Anda berhak memperbarui data profil atau meminta penghapusan akun beserta riwayat data pribadi Anda kapan saja melalui menu Pengaturan Profil di aplikasi Zelvira.</p>
    </div>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFEC4899),
              onRefresh: _fetchPrivacyPolicy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge info header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDF2F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFEC4899),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Perlindungan Data & Privasi",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: Color(0xFFEC4899),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Terakhir diperbarui: ${_formatDate(_updatedAt)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Main Policy HTML Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: HtmlWidget(
                        _htmlContent,
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          height: 1.65,
                          color: Color(0xFF374151),
                        ),
                        customStylesBuilder: (element) {
                          if (element.localName == 'h2') {
                            return {
                              'font-weight': 'bold',
                              'font-size': '16px',
                              'color': '#111827',
                              'margin-top': '16px',
                              'margin-bottom': '8px',
                            };
                          }
                          if (element.localName == 'h3') {
                            return {
                              'font-weight': 'bold',
                              'font-size': '14.5px',
                              'color': '#ec4899',
                              'margin-top': '18px',
                              'margin-bottom': '6px',
                            };
                          }
                          if (element.localName == 'p') {
                            return {
                              'margin-bottom': '10px',
                            };
                          }
                          if (element.localName == 'li') {
                            return {
                              'margin-bottom': '6px',
                            };
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
