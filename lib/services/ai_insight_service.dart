import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/ai_insight_model.dart';

class AiInsightService extends FirestoreService {
  AiInsightService({super.firestore});
  
  Future<AiInsightModel> createAiInsight(AiInsightModel insight) async {
    DocumentReference doc = aiInsights.doc();
    var data = insight.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return AiInsightModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> deleteAiInsight(String id) async {
    await aiInsights.doc(id).delete();
  }
}
