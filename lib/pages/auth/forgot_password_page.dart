import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/button_widget.dart';
import '../../config/app_style.dart';
import '../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppToast.error(context, 'Silakan masukkan alamat email Anda');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.requestForgotPasswordOtp(email);
      if (mounted) {
        AppToast.success(context, 'Kode OTP telah dikirim ke email Anda');
        context.push('/auth/forgot-password-otp', extra: email);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/forgot_password_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.6)),

          // CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Recover Password',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.black87.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Glassmorphic Input
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: 'SEND RESET LINK',
                          onPressed: _handleResetPassword,
                          isLoading: _isLoading,
                          color: AppColors.primary,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black45, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
