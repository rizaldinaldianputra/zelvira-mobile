import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../components/button_widget.dart';
import '../../services/auth_service.dart';

class WhatsappLoginPage extends StatefulWidget {
  const WhatsappLoginPage({super.key});

  @override
  State<WhatsappLoginPage> createState() => _WhatsappLoginPageState();
}

class _WhatsappLoginPageState extends State<WhatsappLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorText;
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'ID');
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phoneToSend = _completePhoneNumber.isNotEmpty
        ? _completePhoneNumber
        : _phoneController.text.trim();

    if (phoneToSend.isEmpty) {
      setState(() => _errorText = 'Silakan masukkan nomor WhatsApp Anda');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final success = await _authService.requestOtp(phoneToSend);
      if (success) {
        if (mounted) {
          context.push('/auth/otp', extra: phoneToSend);
        }
      } else {
        setState(
          () => _errorText =
              'Gagal mengirim OTP. Pastikan nomor terdaftar di WhatsApp.',
        );
      }
    } catch (e) {
      setState(
        () =>
            _errorText = 'Error: ${e.toString().replaceAll("Exception: ", "")}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Image.asset('assets/logo.png'),
              const SizedBox(height: 28),
              const Text(
                'WhatsApp\nAuthentication',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Masukkan nomor WhatsApp Anda. Kami akan mengirimkan 6 digit kode verifikasi rahasia.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 36),

              // International Phone Number Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: _errorText != null
                            ? Colors.red.withValues(alpha: 0.6)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        _phoneNumber = number;
                        _completePhoneNumber = number.phoneNumber ?? '';
                      },
                      onInputValidated: (bool value) {},
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                        useBottomSheetSafeArea: true,
                        setSelectorButtonAsPrefixIcon: true,
                        leadingPadding: 8,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: const TextStyle(
                        color: Colors.black87,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      initialValue: _phoneNumber,
                      textFieldController: _phoneController,
                      formatInput: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputDecoration: const InputDecoration(
                        hintText: '812 3456 7890',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
              ],
              const SizedBox(height: 36),
              CustomButton(
                text: 'Kirim Kode OTP',
                onPressed: _handleSendOtp,
                isLoading: _isLoading,
                color: const Color(0xFF25D366),
                textColor: Colors.white,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
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
