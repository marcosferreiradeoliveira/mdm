import 'dart:convert';
import 'package:admin/constants/constants.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/fcm_config.dart';

class NotificationBloc extends ChangeNotifier {
  Future sendNotification(String title) async {
    final String accessToken = await _getAccessToken();
    final String projectId = serviceCreds['project_id'];

    var notificationBody = {
      "message": {
        "notification": {
          'title': title,
          'body': 'Click here to read more details',
        },
        'data': <String, String>{
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done',
        },
        "topic": Constants.fcmSubscriptionTopic,
      }
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(notificationBody),
      );
      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<String> _getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceCreds);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final authClient = await clientViaServiceAccount(accountCredentials, scopes);

    final credentials = authClient.credentials;
    return credentials.accessToken.data;
  }

  Future saveToDatabase(String? timestamp, String title, String description) async {
    final DocumentReference ref = FirebaseFirestore.instance.collection('notifications').doc(timestamp);
    await ref.set({
      'title': title,
      'description': description,
      'created_at': DateTime.now(),
      'timestamp': timestamp,
    });
  }
}
