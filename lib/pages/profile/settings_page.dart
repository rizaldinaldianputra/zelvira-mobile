import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zelvira/services/auth_service.dart';
import '../../config/app_style.dart';
import 'dart:ui';
import '../../services/app_version_service.dart';
import '../../components/app_update_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
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
            top: 350,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Preferences"),
                  _buildGroupCard([
                    _buildSwitchRow(
                      Icons.notifications_outlined,
                      "Push Notifications",
                      "Receive updates on your orders",
                      _notificationsEnabled,
                      (val) => setState(() => _notificationsEnabled = val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Account Security"),
                  _buildGroupCard([
                    _buildNavRow(
                      context,
                      Icons.lock_outline_rounded,
                      "Change Password",
                      "Secure your account details",
                      () {
                        context.push('/forgot-password');
                      },
                    ),
                    _buildNavRow(
                      context,
                      Icons.language_outlined,
                      "Language",
                      "Indonesian / English",
                      () {
                        _showLanguageSelector(context);
                      },
                    ),
                    _buildNavRow(
                      context,
                      Icons.system_update_rounded,
                      "Versi Aplikasi",
                      "v${AppVersionService.currentAppVersion} • Cek Pembaruan",
                      () {
                        _checkUpdateManually(context);
                      },
                      showDivider: false,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader("Danger Zone"),
                  _buildGroupCard([
                    _buildNavRow(
                      context,
                      Icons.delete_outline_rounded,
                      "Delete Account",
                      "Permanently remove your data",
                      () {
                        _showDeleteAccountDialog(context);
                      },
                      isDanger: true,
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1.1,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSwitchRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          trailing: Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  Widget _buildNavRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
    bool showDivider = true,
  }) {
    final activeColor = isDanger ? Colors.red : AppColors.primary;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: activeColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDanger ? Colors.red : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDanger
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.black38,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Indonesian'),
                trailing: const Icon(Icons.check, color: AppColors.primary),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('English'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Hapus Akun Anda?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Data pribadi Anda akan disamarkan secara permanen dan Anda tidak akan dapat masuk kembali ke akun ini. Apakah Anda yakin?',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            final success = await AuthService().deleteAccount();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Akun Anda berhasil dihapus.'),
                                  backgroundColor: Colors.black87,
                                ),
                              );
                              context.go('/login');
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() => isDeleting = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menghapus akun: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'Ya, Hapus Akun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _checkUpdateManually(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memeriksa pembaruan versi...'),
        duration: Duration(seconds: 1),
      ),
    );

    final checkResult = await AppVersionService().checkUpdate();

    if (!context.mounted) return;

    if (checkResult != null && checkResult.type != AppUpdateType.none) {
      AppUpdateDialog.show(
        context,
        model: checkResult.model,
        currentVersion: checkResult.currentVersion,
        updateType: checkResult.type,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aplikasi Anda sudah versi terbaru! (v${AppVersionService.currentAppVersion})',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
