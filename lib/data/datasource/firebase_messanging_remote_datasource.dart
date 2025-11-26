import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fms/core/constants/variables.dart';
import 'package:fms/data/datasource/auth_remote_datasource.dart';

/// Datasource for handling Firebase Cloud Messaging (Push Notifications).
class FirebaseMessangingRemoteDatasource {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes Firebase Messaging and requests permissions.
  Future<void> initialize() async {
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      await Permission.notification.request();
    }

    final notificationSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint(
        'FirebaseMessaging permissions: '
        '${notificationSettings.authorizationStatus}',
      );
    }

    const initializationSettingsAndroid = AndroidInitializationSettings(
      'ic_permission',
    );
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );

    final fcmToken = await _firebaseMessaging.getToken();

    if (kDebugMode) {
      debugPrint('FCM Token: $fcmToken');
    }

    if (fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(Variables.prefApiKey);

      if (apiKey != null && apiKey.isNotEmpty) {
        try {
          await AuthRemoteDataSource().updateFcmToken(fcmToken);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to update FCM token: $e');
          }
        }
      }
    }

    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessage.listen((message) {
      log(message.notification?.body ?? '');
      log(message.notification?.title ?? '');
    });

    FirebaseMessaging.onMessage.listen(firebaseBackgroundHandler);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(firebaseBackgroundHandler);
  }

  /// Shows a local notification.
  Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
  }) async {
    return flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'com.querta.fms',
          'app',
          importance: Importance.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();

    FirebaseMessangingRemoteDatasource().firebaseBackgroundHandler(message);
  }

  Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    showNotification(
      title: message.notification!.title,
      body: message.notification!.body,
    );
  }
}
