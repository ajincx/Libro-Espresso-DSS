import 'package:cloud_firestore/cloud_firestore.dart';

class SettingModel {
  final String id;
  final String key;
  final dynamic value;
  final DateTime updatedAt;

  SettingModel({required this.id, required this.key, required this.value, required this.updatedAt});

  factory SettingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SettingModel(
      id: documentId,
      key: data['key'] ?? documentId,
      value: data['value'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
