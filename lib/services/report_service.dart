import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/report_model.dart';

class ReportService extends FirestoreService {
  ReportService({super.firestore});
  
  Future<ReportModel> saveReport(ReportModel report) async {
    DocumentReference doc = reports.doc();
    var data = report.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return ReportModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }
  
  Future<void> deleteReport(String id) async {
    await reports.doc(id).delete();
  }
}
