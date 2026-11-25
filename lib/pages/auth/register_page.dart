import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/button_widget.dart';
import '../../components/lottie_dialog.dart';
import '../../services/auth_service.dart';
import '../../config/app_style.dart';
import 'dart:ui';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      AppToast.error(context, 'Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.register(email, password, fullName);
      if (user != null) {
        if (mounted) {
          LottieDialog.show(
            context: context,
            lottieAsset: 'assets/lottie/success.json',
            title: 'Welcome!',
            message: 'Your account has been created successfully.',
            buttonText: 'START SHOPPING',
            onButtonPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/home');
            },
            buttonColor: AppColors.primary,
          );
        }
      } else {
        if (mounted) {
          LottieDialog.show(
            context: context,
            lottieAsset: 'assets/lottie/error.json',
            title: 'Oops!',
            message: 'Registration failed. This email might already be in use.',
            buttonText: 'TRY AGAIN',
            buttonColor: Colors.redAccent,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        LottieDialog.show(
          context: context,
          lottieAsset: 'assets/lottie/error.json',
          title: 'Connection Error',
          message: 'Please check your internet connection and try again.',
          buttonText: 'OK',
          buttonColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.loginWithGoogle();
      if (user != null) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        if (mounted) {
          LottieDialog.show(
            context: context,
            lottieAsset: 'assets/lottie/error.json',
            title: 'Login Failed',
            message: 'Social login was cancelled or failed. Please try again.',
            buttonText: 'OK',
            buttonColor: Colors.redAccent,
          );
        }
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
          // GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFEAEE), // Soft pink/white
                  Color(0xFFF9FAFC), // White background
                  Color(0xFFE8F0FE), // Soft blue
                ],
              ),
            ),
          ),

          // DECORATIVE SHAPES
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // BLUR EFFECT OVER SHAPES
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
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
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create Account',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Join the Zelvira community today',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Glassmorphic Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
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
                          controller: _fullNameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscure: _obscurePassword,
                          toggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: 'GET STARTED',
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                          color: AppColors.primary,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Sign up with Google',
                          onPressed: _handleGoogleLogin,
                          isLoading: _isLoading,
                          color: Colors.white,
                          textColor: Colors.black87,
                          icon: Image.asset('assets/google.png', height: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'By registering, you agree to our Terms',
                          style: TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
    bool isPassword = false,
    bool? obscure,
    VoidCallback? toggleObscure,
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
            obscureText: isPassword ? (obscure ?? true) : false,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black45, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure! ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black45,
                        size: 20,
                      ),
                      onPressed: toggleObscure,
                    )
                  : null,
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
