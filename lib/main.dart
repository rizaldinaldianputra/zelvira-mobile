import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'routes/app_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:toastification/toastification.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Portrait Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      "Firebase Messaging permission status: ${settings.authorizationStatus}",
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      debugPrint("FCM Token refreshed: $fcmToken");
      AuthService().syncFcmToken();
    });

    messaging
        .getToken()
        .then((token) {
          debugPrint("Current FCM Token: $token");
          if (token != null && token.isNotEmpty) {
            AuthService().syncFcmToken();
          }
        })
        .catchError((e) {
          debugPrint("Error fetching FCM token: $e");
        });

    try {
      await messaging.subscribeToTopic('all');
      await messaging.subscribeToTopic('news');
      debugPrint("Subscribed to broadcast topics: all, news");
    } catch (e) {
      debugPrint("Failed to subscribe to topics: $e");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title =
          message.notification?.title ??
          message.data['title'] ??
          'Notifikasi Baru';

      final body =
          message.notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          '';

      debugPrint("Foreground message received: $title - $body");

      toastification.show(
        title: Text(title),
        description: Text(body),
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 4),
        icon: const Icon(Icons.notifications_active),
        callbacks: ToastificationCallbacks(
          onTap: (toastItem) {
            NotificationNavigationService.handleNotificationClick(message.data);
          },
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked from background: ${message.data}");
      NotificationNavigationService.handleNotificationClick(message.data);
    });

    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          "Notification opened app from terminated state: ${message.data}",
        );
        NotificationNavigationService.handleNotificationClick(message.data);
      }
    });
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Handling background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: FeatureDiscovery(
        recordStepsInSharedPreferences: true,
        child: MaterialApp.router(
          title: 'Zelvira',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.pink,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.pink,
              primary: Colors.pink,
            ),
            useMaterial3: true,
            fontFamily: 'Outfit',
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
