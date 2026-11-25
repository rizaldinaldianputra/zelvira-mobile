import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/button_widget.dart';
import '../../components/lottie_dialog.dart';
import '../../config/app_style.dart';
import '../../services/auth_service.dart';

class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const CreateNewPasswordPage({super.key, this.email = '', this.code = ''});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      AppToast.error(context, 'Silakan isi kedua kolom password');
      return;
    }

    if (password != confirmPassword) {
      AppToast.error(context, 'Password konfirmasi tidak cocok');
      return;
    }

    if (password.length < 6) {
      AppToast.error(context, 'Password minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(widget.email, widget.code, password);
      if (mounted) {
        setState(() => _isLoading = false);
        LottieDialog.show(
          context: context,
          lottieAsset: 'assets/lottie/success.json',
          title: 'Berhasil!',
          message:
              'Password akun Anda telah berhasil direset. Silakan login kembali dengan password baru Anda.',
          buttonText: 'KE HALAMAN LOGIN',
          onButtonPressed: () {
            Navigator.pop(context); // Close dialog
            context.go('/login'); // Back to login page
          },
          buttonColor: AppColors.primary,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(
          context,
          'Gagal reset password: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Create New\nPassword',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your new password must be different from previously used passwords.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // New Password Field
              _buildPasswordField(
                controller: _passwordController,
                label: 'NEW PASSWORD',
                hintText: 'Enter new password',
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 24),

              // Confirm Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'CONFIRM PASSWORD',
                hintText: 'Confirm your new password',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),

              const SizedBox(height: 48),
              CustomButton(
                text: 'Save New Password',
                onPressed: _handleSavePassword,
                isLoading: _isLoading,
                color: AppColors.primary,
                textColor: Colors.white,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Outfit',
            ),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
