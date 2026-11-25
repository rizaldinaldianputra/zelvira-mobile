import 'package:flutter/material.dart';

class ErrorRetryWidget extends StatefulWidget {
  final Future<void> Function()? onRetryAsync;
  final VoidCallback? onRetry;
  final String message;
  final double height;

  const ErrorRetryWidget({
    super.key,
    this.onRetry,
    this.onRetryAsync,
    this.message = 'Gagal memuat data. Periksa koneksi Anda.',
    this.height = 150,
  });

  @override
  State<ErrorRetryWidget> createState() => _ErrorRetryWidgetState();
}

class _ErrorRetryWidgetState extends State<ErrorRetryWidget> {
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
        // Keep loading visual for at least 400ms for smooth feedback
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isRetrying ? null : _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16),
                        SizedBox(width: 6),
                        Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
