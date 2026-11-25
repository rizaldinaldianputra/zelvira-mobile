import 'package:zelvira/components/notifcation_widget.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../components/button_widget.dart';
import '../../services/auth_service.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  final String email;
  const ForgotPasswordOtpPage({super.key, required this.email});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorText;

  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _errorText = 'Silakan masukkan 6 digit kode OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authService.verifyForgotPasswordOtp(widget.email, code);
      if (mounted) {
        context.push(
          '/auth/create-new-password',
          extra: {'email': widget.email, 'code': code},
        );
      }
    } catch (e) {
      setState(
        () => _errorText =
            'Verifikasi gagal: ${e.toString().replaceAll("Exception: ", "")}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authService.requestForgotPasswordOtp(widget.email);
      _startTimer();
      if (mounted) {
        AppToast.success(
          context,
          'Kode OTP berhasil dikirim ulang ke Email Anda!',
        );
      }
    } catch (e) {
      setState(
        () => _errorText =
            'Error kirim OTP: ${e.toString().replaceAll("Exception: ", "")}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Outfit',
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF25D366), width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFF25D366), width: 1.5),
      ),
    );

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
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Image.asset('assets/logo.png', height: 48),
              const SizedBox(height: 28),
              const Text(
                'Verifikasi Kode',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                    fontFamily: 'Outfit',
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Kami telah mengirimkan 6 digit kode OTP ke Email:\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  onCompleted: (pin) => _handleVerify(),
                  showCursor: true,
                  separatorBuilder: (index) => const SizedBox(width: 8),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Tidak menerima kode? ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Outfit',
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendTimer == 0 && !_isLoading
                        ? _handleResend
                        : null,
                    child: Text(
                      _resendTimer == 0
                          ? 'Kirim Ulang'
                          : 'Kirim Ulang (${_resendTimer}s)',
                      style: TextStyle(
                        color: _resendTimer == 0
                            ? const Color(0xFF25D366)
                            : Colors.grey[400],
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: 'Verifikasi',
                onPressed: _handleVerify,
                isLoading: _isLoading,
                color: const Color(0xFF25D366),
                textColor: Colors.white,
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
