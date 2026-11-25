import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../config/app_style.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      'title': 'Koleksi Fashion Terkini',
      'desc':
          'Temukan berbagai pilihan busana wanita terbaru yang didesain untuk kenyamanan dan gaya Anda setiap hari.',
      'lottie': 'assets/lottie/fashion.json',
    },
    {
      'title': 'Belanja Tanpa Ribet',
      'desc':
          'Nikmati kemudahan berbelanja dengan antarmuka yang modern, cepat, dan aman untuk segala kebutuhan fashion Anda.',
      'lottie': 'assets/lottie/shopping.json',
    },
    {
      'title': 'Pengiriman Cepat & Aman',
      'desc':
          'Pesanan Anda akan sampai tepat waktu dengan sistem logistik terpercaya ke seluruh pelosok negeri.',
      'lottie': 'assets/lottie/delivery.json',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() => _currentPage = value);
                },
                itemCount: _introData.length,
                itemBuilder: (context, index) => _buildSlide(index),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _introData.length,
                      (index) => _buildDot(index),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _currentPage == _introData.length - 1
                      ? _buildGetStartedButton()
                      : _buildNextButton(),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Lewati',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight < 650;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isSmallHeight ? 16 : 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    _introData[index]['lottie']!,
                    height: isSmallHeight ? 220 : 300,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: isSmallHeight ? 24 : 40),

                  Text(
                    _introData[index]['title']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: isSmallHeight ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _introData[index]['desc']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'LANJUT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.go('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'MULAI SEKARANG',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
