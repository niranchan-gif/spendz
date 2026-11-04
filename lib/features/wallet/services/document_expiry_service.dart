import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../models/wallet_document_model.dart';
import '../../../database/wallet_document_repository.dart';

/// Gateway abstraction for local notifications (enables mockability in host unit tests).
abstract class LocalNotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAll();
}

/// Production implementation using FlutterLocalNotificationsPlugin and Timezone.
class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: settings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init exception (non-fatal): $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await androidImpl?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    return false;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'spendz_document_expiry_channel',
        'Document Expiry Alerts',
        channelDescription:
            'Alerts when your vault documents (DL, Passport, Insurance) are expiring.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      const darwinDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling local notification $id: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}

/// In-memory mock for automated unit testing.
class MockLocalNotificationGateway implements LocalNotificationGateway {
  final Map<int, Map<String, dynamic>> scheduledNotifications = {};
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    scheduledNotifications[id] = {
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
    };
  }

  @override
  Future<void> cancelNotification(int id) async {
    scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
  }
}

/// Represents the status and days remaining for an expiring document.
class DocumentExpiryInfo {
  final WalletDocumentModel document;
  final int daysRemaining;
  final bool isExpired;
  final bool isExpiringSoon; // <= 30 days

  const DocumentExpiryInfo({
    required this.document,
    required this.daysRemaining,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  String get formattedStatus {
    if (isExpired) {
      final daysAgo = daysRemaining.abs();
      return daysAgo == 0
          ? 'Expired today'
          : 'Expired $daysAgo day${daysAgo == 1 ? "" : "s"} ago';
    } else if (daysRemaining == 0) {
      return 'Expires today';
    } else if (daysRemaining == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $daysRemaining days';
    }
  }
}

/// Service managing document expiry detection, notifications, and proactive alerts.
class DocumentExpiryService {
  final WalletDocumentRepository _documentRepository;
  final LocalNotificationGateway _notificationGateway;

  // Notification schedule offsets in days before expiry
  static const List<int> reminderIntervals = [30, 7, 1, 0];

  DocumentExpiryService({
    WalletDocumentRepository? documentRepository,
    LocalNotificationGateway? notificationGateway,
  }) : _documentRepository = documentRepository ?? WalletDocumentRepository(),
       _notificationGateway =
           notificationGateway ?? FlutterLocalNotificationGateway();

  Future<void> initialize() async {
    await _notificationGateway.initialize();
  }

  /// Calculates deterministic base integer ID for a document to prevent ID collisions.
  int getBaseNotificationId(String documentId) {
    return (documentId.hashCode.abs() % 1000000) * 10;
  }

  /// Evaluates and groups all registered documents by expiry status.
  Future<List<DocumentExpiryInfo>> getExpiryAssessments({
    DateTime? referenceNow,
  }) async {
    final docs = await _documentRepository.getAllDocuments();
    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final results = <DocumentExpiryInfo>[];

    for (final doc in docs) {
      if (doc.expiryDate == null) continue;

      final expDate = DateTime(
        doc.expiryDate!.year,
        doc.expiryDate!.month,
        doc.expiryDate!.day,
      );

      final differenceDays = expDate.difference(today).inDays;
      final isExpired = differenceDays < 0;
      final isExpiringSoon = differenceDays >= 0 && differenceDays <= 30;

      results.add(
        DocumentExpiryInfo(
          document: doc,
          daysRemaining: differenceDays,
          isExpired: isExpired,
          isExpiringSoon: isExpiringSoon,
        ),
      );
    }

    // Sort: Expired first, then closest upcoming expiry
    results.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return results;
  }

  /// Returns documents expiring within [days] (default 30).
  Future<List<DocumentExpiryInfo>> getUpcomingExpiries({
    int days = 30,
    DateTime? referenceNow,
  }) async {
    final all = await getExpiryAssessments(referenceNow: referenceNow);
    return all
        .where((info) => !info.isExpired && info.daysRemaining <= days)
        .toList();
  }

  /// Returns already expired documents.
  Future<List<DocumentExpiryInfo>> getExpiredDocuments({
    DateTime? referenceNow,
  }) async {
    final all = await getExpiryAssessments(referenceNow: referenceNow);
    return all.where((info) => info.isExpired).toList();
  }

  /// Schedules all reminder intervals (30 days, 7 days, 1 day, day of expiry) for [document].
  /// Cancels previous notifications for this document to avoid duplicates.
  Future<void> scheduleRemindersForDocument(
    WalletDocumentModel document, {
    DateTime? referenceNow,
  }) async {
    if (document.expiryDate == null) {
      await cancelRemindersForDocument(document.id);
      return;
    }

    // Cancel prior notifications first to prevent stale dates or duplicates
    await cancelRemindersForDocument(document.id);

    final now = referenceNow ?? DateTime.now();
    final baseId = getBaseNotificationId(document.id);
    final expiry = document.expiryDate!;

    for (int i = 0; i < reminderIntervals.length; i++) {
      final daysBefore = reminderIntervals[i];
      final targetDate = DateTime(
        expiry.year,
        expiry.month,
        expiry.day - daysBefore,
        9, // 9:00 AM local time
        0,
      );

      // Only schedule if target is in the future
      if (targetDate.isAfter(now)) {
        final notifId = baseId + i;
        final title = daysBefore == 0
            ? 'Document Expired Today!'
            : 'Document Expiring in $daysBefore Days';
        final body =
            '${document.documentName} is expiring on ${expiry.day}/${expiry.month}/${expiry.year}. Please review or renew.';

        await _notificationGateway.scheduleNotification(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: targetDate,
        );
      }
    }
  }

  /// Cancels all scheduled notifications associated with [documentId].
  Future<void> cancelRemindersForDocument(String documentId) async {
    final baseId = getBaseNotificationId(documentId);
    for (int i = 0; i < reminderIntervals.length; i++) {
      await _notificationGateway.cancelNotification(baseId + i);
    }
  }
}
