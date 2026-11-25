import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../services/auth_service.dart';
import '../../services/notification_navigation_service.dart';
import '../../services/app_version_service.dart';
import '../../components/app_update_dialog.dart';
import '../../config/app_style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _loadingController;

  final AuthService _authService = AuthService();
  final AppVersionService _versionService = AppVersionService();

  bool _showLoading = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();

    // Logo animation: slow and smooth from small to full size.
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.12, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoController.forward();

    // Show loading after logo starts appearing.
    _loadingTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showLoading = true);
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      _versionService.checkUpdate(),
    ]);

    final checkResult = results[1] as AppUpdateCheckResult?;

    if (!mounted) return;

    if (checkResult != null && checkResult.type != AppUpdateType.none) {
      if (checkResult.type == AppUpdateType.force) {
        await AppUpdateDialog.show(
          context,
          model: checkResult.model,
          currentVersion: checkResult.currentVersion,
          updateType: AppUpdateType.force,
        );
      } else if (checkResult.type == AppUpdateType.optional) {
        await AppUpdateDialog.show(
          context,
          model: checkResult.model,
          currentVersion: checkResult.currentVersion,
          updateType: AppUpdateType.optional,
          onDismiss: () {
            if (mounted) {
              _proceedToNextScreen();
            }
          },
        );
      }
    } else {
      _proceedToNextScreen();
    }
  }

  Future<void> _proceedToNextScreen() async {
    if (!mounted) return;

    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final pendingRoute = NotificationNavigationService.consumePendingRoute();
      final pendingExtra = NotificationNavigationService.consumePendingExtra();

      if (pendingRoute != null && pendingRoute.isNotEmpty) {
        if (pendingExtra != null) {
          context.go(pendingRoute, extra: pendingExtra);
        } else {
          context.go(pendingRoute);
        }
      } else {
        context.go('/home');
      }
    } else {
      context.go('/intro');
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // CENTER LOGO
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),

            // BOTTOM LOADING
            Positioned(
              left: 32,
              right: 32,
              bottom: 35,
              child: AnimatedOpacity(
                opacity: _showLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated progress bar
                    SizedBox(
                      width: 150,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: null,
                              minHeight: 3,
                              backgroundColor: const Color(0xFFFFE5F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Text(
                      'Memuat Zelvira...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
