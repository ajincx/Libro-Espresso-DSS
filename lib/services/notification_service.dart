import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/notification_model.dart';

class NotificationService extends FirestoreService {
  NotificationService({super.firestore});
  
  Future<NotificationModel> createNotification(NotificationModel notification) async {
    DocumentReference doc = notifications.doc();
    var data = notification.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return NotificationModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> markAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': true});
  }
  
  Future<void> deleteNotification(String id) async {
    await notifications.doc(id).delete();
  }
}
