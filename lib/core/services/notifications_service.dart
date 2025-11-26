import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late GlobalKey<NavigatorState> navigatorKey;

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    AndroidInitializationSettings androidIcon =
        const AndroidInitializationSettings('ic_notification'),
  }) async {
    this.navigatorKey = navigatorKey;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final initSettings = InitializationSettings(android: androidIcon);
    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final route = resp.payload ?? '';
        _openRoute(route);
      },
    );

    final android = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tarefas_channel',
        'Tarefas',
        description: 'Alertas de tarefas atribuídas',
        importance: Importance.high,
      ),
    );

    FirebaseMessaging.onMessage.listen((msg) async {
      final title = msg.notification?.title ?? 'Nova tarefa';
      final body = msg.notification?.body ?? '';
      final route = msg.data['route'] ?? '';
      await _fln.show(
        msg.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tarefas_channel',
            'Tarefas',
            channelDescription: 'Alertas de tarefas atribuídas',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: route,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final route = msg.data['route'] ?? '';
      _openRoute(route);
    });

    final initialMsg = await _messaging.getInitialMessage();
    if (initialMsg != null) {
      final route = initialMsg.data['route'] ?? '';
      _openRoute(route);
    }
  }

  // ALTERADO: agora recebe empresaId!
  Future<void> saveCurrentToken(String empresaId, String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    final ref = FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('usuarios')
        .doc(uid)
        .collection('tokens')
        .doc(token);

    await ref.set({
      'token': token,
      'plataforma': Platform.operatingSystem,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('usuarios')
          .doc(uid)
          .collection('tokens')
          .doc(newToken)
          .set({
            'token': newToken,
            'plataforma': Platform.operatingSystem,
            'atualizadoEm': FieldValue.serverTimestamp(),
          });
    });
  }

  void _openRoute(String route) {
    if (route.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (route.startsWith('/tarefas/')) {
      final id = route.split('/').last;
      nav.pushNamed('/_push_tarefa', arguments: id);
      return;
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Logger opcional (pode deixar vazio ou inserir logs de debug)
}
