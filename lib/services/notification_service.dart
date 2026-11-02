
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static StreamSubscription<RemoteMessage>? _subscription;

  // Điền Web Push public key từ Firebase Console
  static const String vapidKey = 'BGe1cdQqjXs4O0fFRtKj2ZF2Yp2gGYZioZe0pJCChN3PtsnmOZ7yLRiUxo14Ybu5S3ToNiMShs-JP1m05wjDYUs';

  // Giữ nguyên tên hàm để không ảnh hưởng code đang gọi.
  // Hàm này giờ hỗ trợ cả Android và Chrome.
  static Future<String?> enableAndroid(
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Chỉ hỗ trợ Android và Web.');
    }

    final messaging = FirebaseMessaging.instance;

    // Kiểm tra trình duyệt có hỗ trợ FCM không
    if (!await messaging.isSupported()) {
      throw UnsupportedError('Thiết bị không hỗ trợ FCM.');
    }

    // Xin quyền nhận thông báo
    final settings = await messaging.requestPermission();

    if (settings.authorizationStatus ==
        AuthorizationStatus.denied) {
      throw StateError('Bạn chưa cấp quyền thông báo.');
    }

    // Lấy FCM Token để thử gửi từ Firebase Console.
    // Android không cần VAPID; Web cần VAPID.
    final token = await messaging.getToken(
      vapidKey: kIsWeb ? vapidKey : null,
    );

    // Nhận thông báo khi ứng dụng đang mở
    _subscription ??= FirebaseMessaging.onMessage.listen((message) {
      final title =
          message.notification?.title ?? 'UTH Todo';

      final body =
          message.notification?.body ?? 'Có thông báo mới.';

      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$title: $body')),
      );
    });

    return token;
  }
}
