import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version_model.dart';
import '../services/app_version_service.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionModel model;
  final String currentVersion;
  final AppUpdateType updateType;
  final VoidCallback? onDismiss;

  const AppUpdateDialog({
    super.key,
    required this.model,
    required this.currentVersion,
    required this.updateType,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required AppVersionModel model,
    required String currentVersion,
    required AppUpdateType updateType,
    VoidCallback? onDismiss,
  }) async {
    final isForce = updateType == AppUpdateType.force;

    await showDialog(
      context: context,
      barrierDismissible: !isForce,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => PopScope(
        canPop: !isForce,
        child: AppUpdateDialog(
          model: model,
          currentVersion: currentVersion,
          updateType: updateType,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  Future<void> _launchUpdateUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(model.downloadUrl.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka link: ${model.downloadUrl}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = updateType == AppUpdateType.force;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Decorative Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 28, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isForce
                        ? [const Color(0xFFFF416C), const Color(0xFFFF4B2B)]
                        : [const Color(0xFFE91E63), const Color(0xFFFF6090)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.system_update_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isForce ? 'WAJIB PERBARUI' : 'PEMBARUAN TERSEDIA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      model.title.isNotEmpty
                          ? model.title
                          : 'Pembaruan Tersedia',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Version comparison badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'v$currentVersion',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            'v${model.latestVersion}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message / Changelog
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: SingleChildScrollView(
                        child: Text(
                          model.message.isNotEmpty
                              ? model.message
                              : 'Tingkatkan aplikasi ke versi terbaru untuk pengalaman berbelanja yang lebih stabil dan fitur terlengkap.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUpdateUrl(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text(
                          'Perbarui Sekarang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Optional skip button (only if NOT forced)
                    if (!isForce) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDismiss?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Nanti Saja (Lewati)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
