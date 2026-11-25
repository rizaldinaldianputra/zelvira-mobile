import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/button_widget.dart';
import '../../config/app_style.dart';

class ErrorPage extends StatelessWidget {
  final String errorMessage;

  const ErrorPage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Retry',
              color: AppColors.primary,
              onPressed: () {
                context.pop(true); // Return true for retry
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Back',
              color: Colors.grey.shade200,
              textColor: Colors.black87,
              onPressed: () {
                context.pop(false); // Return false for back
              },
            ),
          ],
        ),
      ),
    );
  }
}
