import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../models/user_model.dart';
import '../../config/app_style.dart';
import '../../components/button_widget.dart';
import '../../services/common_service.dart';
import '../../riverpod/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/url_utils.dart';
import 'dart:io';
import 'dart:ui';

class ProfileEditPage extends ConsumerStatefulWidget {
  final UserModel user;

  const ProfileEditPage({super.key, required this.user});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage(pickedFile.path);
    }
  }

  Future<void> _uploadImage(String path) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.uploadProfilePicture(path);
      if (updatedUser != null) {
        await ref.read(authProvider.notifier).checkLoginStatus();
        if (mounted) {
          toastification.show(
            context: context,
            title: const Text('Berhasil'),
            description: const Text('Foto profil berhasil diperbarui'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Gagal'),
          description: Text('Gagal mengunggah foto: $e'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final commonService = CommonService();
      final response = await commonService.put(
        '/api/v1/auth/me',
        data: {
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
        },
      );

      if (response.statusCode == 200) {
        await ref.read(authProvider.notifier).checkLoginStatus();

        if (mounted) {
          toastification.show(
            context: context,
            title: const Text('Berhasil'),
            description: const Text('Profil berhasil diperbarui'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Gagal'),
          description: Text('Terjadi kesalahan: $e'),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
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
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl:
                                            (widget.user.profilePicture !=
                                                    null &&
                                                widget
                                                    .user
                                                    .profilePicture!
                                                    .isNotEmpty)
                                            ? UrlUtils.formatImageUrl(
                                                widget.user.profilePicture,
                                              )
                                            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.user.fullName ?? 'User')}&background=random',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey.shade300,
                                              highlightColor:
                                                  Colors.grey.shade100,
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Image.network(
                                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.user.fullName ?? 'User')}&background=random',
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildTextField(
                        'Nama Lengkap',
                        _fullNameController,
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        'Email',
                        _emailController,
                        Icons.email_outlined,
                        isReadOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        'Nomor WhatsApp',
                        _phoneController,
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 32),

                      CustomButton(
                        text: 'SIMPAN',
                        onPressed: _updateProfile,
                        isLoading: _isLoading,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: isReadOnly
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.6),
      ),
      validator: (value) {
        if (!isReadOnly && (value == null || value.isEmpty)) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }
}
