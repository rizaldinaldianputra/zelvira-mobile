import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class LottieDialog extends StatelessWidget {
  final String lottieAsset;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? buttonColor;

  const LottieDialog({
    super.key,
    required this.lottieAsset,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(lottieAsset, width: 150, height: 150, repeat: false),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (buttonText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed ?? () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor ?? Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    buttonText!,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String lottieAsset,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
    Color? buttonColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LottieDialog(
        lottieAsset: lottieAsset,
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        buttonColor: buttonColor,
      ),
    );
  }
}
