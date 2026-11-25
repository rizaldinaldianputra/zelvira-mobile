import 'package:flutter/material.dart';

class ErrorPage extends StatefulWidget {
  final Future<void> Function()? onRetryAsync;
  final VoidCallback? onRetry;
  final String message;

  const ErrorPage({
    super.key,
    this.onRetry,
    this.onRetryAsync,
    this.message = 'Oops, terjadi kesalahan. Periksa koneksi internet Anda atau coba lagi beberapa saat.',
  });

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      if (widget.onRetryAsync != null) {
        await widget.onRetryAsync!();
      } else if (widget.onRetry != null) {
        widget.onRetry!();
      }
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Koneksi Terputus',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Coba Lagi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
