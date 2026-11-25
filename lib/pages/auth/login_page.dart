import 'package:zelvira/components/notifcation_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelvira/config/app_style.dart';
import 'package:toastification/toastification.dart';
import '../../components/button_widget.dart';
import '../../services/auth_service.dart';
import '../../riverpod/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  VideoPlayerController? _controller;
  @override
  void initState() {
    super.initState();
    _loadRememberMe();

    _controller = VideoPlayerController.asset('assets/video.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller!
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _showEmailLoginBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sign In with Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome back! Please enter your details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSheetTextField(
                      controller: _emailController,
                      hintText: 'Email / Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildSheetTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleObscure: () => setSheetState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  onChanged: (value) {
                                    setSheetState(() => _rememberMe = value!);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/forgot-password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'LOGIN',
                      onPressed: () {
                        if (!_isLoading) _handleLogin(setSheetState);
                      },
                      isLoading: _isLoading,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close the bottom sheet
                            context.push('/register'); // Go to register page
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(StateSetter setSheetState) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppToast.error(context, 'Please fill all fields');
      return;
    }

    setSheetState(() => _isLoading = true);
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(email, password);
      final authState = ref.read(authProvider);

      if (authState.value != null) {
        await _saveRememberMe();
        await refreshAllAppData(ref);
        if (mounted) {
          Navigator.pop(context);
          context.go('/home');
        }
      } else {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text('Login Failed'),
            description: const Text(
              'Invalid email or password. Please try again.',
            ),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Connection Error'),
          description: const Text(
            'Unable to connect to the server. Please check your network.',
          ),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setSheetState(() => _isLoading = false);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.loginWithGoogle();
      if (user != null) {
        ref.read(authProvider.notifier).setUser(user);
        await refreshAllAppData(ref);
        if (mounted) {
          context.go('/home');
        }
      } else {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text('Login Canceled'),
            description: const Text('Google login was canceled by the user.'),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Google Login Failed'),
          description: Text(msg),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 7),
        );
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
          // 🎥 BACKGROUND VIDEO
          if (_controller?.value.isInitialized ?? false)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            const SizedBox(),
          Container(color: Colors.black.withValues(alpha: 0.4)),

          // 🧾 CONTENT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Z',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'ZELVIRA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Outfit',
                    color: Colors.white,
                  ),
                ),

                const Text(
                  'Minimalist Elegance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                  ),
                ),

                const Spacer(),

                const Text(
                  'Empower your style with\ntimeless essentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 48),

                CustomButton(
                  text: 'Sign in with Google',
                  onPressed: () {
                    _handleGoogleLogin();
                  },
                  isLoading: _isLoading,
                  color: Colors.white,
                  textColor: Colors.black87,
                  icon: Image.asset('assets/google.png', height: 20),
                ),
                const SizedBox(height: 16),

                CustomButton(
                  text: 'Sign in with Whatsapp',
                  onPressed: () {
                    context.push('/auth/whatsapp');
                  },
                  isLoading: _isLoading,
                  color: Colors.green,
                  textColor: Colors.white,
                  icon: Image.asset(
                    'assets/whatsaap.png',
                    color: Colors.white,
                    height: 20,
                  ),
                ),
                const SizedBox(height: 16),

                CustomButton(
                  isLoading: _isLoading,

                  text: 'Sign in with Email',
                  onPressed: _showEmailLoginBottomSheet,
                  color: AppColors.primary,
                  icon: Icon(Icons.email, color: Colors.white),
                ),

                const SizedBox(height: 32),

                const Text(
                  'By signing in, you agree to our Terms and Conditions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Outfit',
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
