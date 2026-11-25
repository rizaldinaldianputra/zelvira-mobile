import 'package:flutter/material.dart';
import '../../config/app_style.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tentang Zelvira',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'Z',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ZELIXA v1.0.0',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Minimalist Elegance',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text(
              'Zelvira adalah platform e-commerce fashion yang mengedepankan kualitas dan desain minimalis. Kami percaya bahwa gaya sejati tidak lekang oleh waktu dan kenyamanan adalah prioritas utama.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              'Misi Kami',
              'Memberikan akses ke fashion berkualitas tinggi dengan harga yang jujur dan transparansi penuh.',
              Icons.rocket_launch_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Kualitas Terjamin',
              'Setiap produk melalui kurasi ketat untuk memastikan material terbaik sampai di tangan Anda.',
              Icons.verified_outlined,
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              '© 2026 Zelvira Team. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
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
