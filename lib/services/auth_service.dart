import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'common_service.dart';
import 'session_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CommonService _commonService = CommonService();
  final SessionService _sessionService = SessionService();

  /// 🔥 GOOGLE SIGN IN (NATIVE)
  Future<UserModel?> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '76456849266-1h2btpc4a06lcaoo9d7ku2g8vh9dperu.apps.googleusercontent.com',
        scopes: const [
          'email',
          'profile',
        ],
      );

      // Logout dulu biar user bisa pilih akun kalau sebelumnya nyangkut
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Failed to get ID Token from Google");
      }

      // Kirim ID token ke backend Spring Boot
      final response = await _commonService.post(
        '/api/v1/auth/google',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);

        final userResponse = await _commonService.get('/api/v1/auth/me');
        if (userResponse.statusCode == 200) {
          final data = userResponse.data['data'];
          final user = UserModel.fromJson(data);
          await _sessionService.saveUser(user);
          await syncFcmToken();
          return user;
        }
      }
      return null;
    } catch (e) {
      final str = e.toString();
      if (str.contains('10') || str.contains('ApiException')) {
        throw Exception(
          'Google Sign-In Error (ApiException: 10): SHA-1 fingerprint belum terdaftar pada OAuth Android Client di Google Cloud Console untuk package com.zelvira.ecommerce.',
        );
      }
      throw Exception(e.toString());
    }
  }

  // ==========================
  // ✅ OTP WHATSAPP (TIDAK DIUBAH)
  // ==========================

  Future<bool> requestOtp(String phoneNumber) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/otp/request',
        data: {'phoneNumber': phoneNumber},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> verifyOtp(String phoneNumber, String code) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/otp/login',
        data: {'phoneNumber': phoneNumber, 'code': code},
      );

      if (response.statusCode == 200 &&
          response.data['data'] != null &&
          response.data['data']['token'] != null) {
        final token = response.data['data']['token'];

        await _storage.write(key: 'auth_token', value: token);

        final userResponse = await _commonService.get('/api/v1/auth/me');
        if (userResponse.statusCode == 200) {
          final data = userResponse.data['data'];
          final user = UserModel.fromJson(data);
          await _sessionService.saveUser(user);
          await syncFcmToken();
          return user;
        }
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// 📧 EMAIL REGISTER
  Future<UserModel?> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/register',
        data: {'email': email, 'password': password, 'fullName': fullName},
      );

      if (response.statusCode == 201 && response.data['data'] != null) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);

        final userResponse = await _commonService.get('/api/v1/auth/me');
        if (userResponse.statusCode == 200) {
          final data = userResponse.data['data'];
          final user = UserModel.fromJson(data);
          await _sessionService.saveUser(user);
          await syncFcmToken();
          return user;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 📧 EMAIL LOGIN
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);

        final userResponse = await _commonService.get('/api/v1/auth/me');
        if (userResponse.statusCode == 200) {
          final data = userResponse.data['data'];
          final user = UserModel.fromJson(data);
          await _sessionService.saveUser(user);
          await syncFcmToken();
          return user;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _sessionService.clearSession();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<UserModel?> getProfile() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      final response = await _commonService.get('/api/v1/auth/me');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final user = UserModel.fromJson(response.data['data']);
        await _sessionService.saveUser(user);
        await syncFcmToken();
        return user;
      }
      return await _sessionService.getUser();
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> uploadProfilePicture(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _commonService.post(
        '/api/v1/auth/me/picture',
        data: formData,
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> syncFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[FCM] Syncing token to backend: $token');
        final response = await _commonService.post(
          '/api/v1/auth/me/fcm-token',
          data: {'fcmToken': token},
        );
        debugPrint('[FCM] Token sync response status: ${response.statusCode}');
      } else {
        debugPrint('[FCM] No token available to sync to backend.');
      }
    } catch (e) {
      debugPrint('[FCM] Error syncing FCM token: $e');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _commonService.delete('/api/v1/auth/me');
      if (response.statusCode == 200) {
        await _storage.delete(key: 'auth_token');
        await _sessionService.clearSession();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> requestForgotPasswordOtp(String email) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/forgot-password/request',
        data: {'email': email.trim()},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyForgotPasswordOtp(String email, String code) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/forgot-password/verify',
        data: {'email': email.trim(), 'code': code.trim()},
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _commonService.post(
        '/api/v1/auth/forgot-password/reset',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword.trim(),
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}
