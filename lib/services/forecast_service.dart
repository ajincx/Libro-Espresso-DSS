import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/forecast_model.dart';

class ForecastService extends FirestoreService {
  ForecastService({super.firestore});
  
  Future<ForecastModel> createForecast(ForecastModel forecast) async {
    DocumentReference doc = forecasts.doc();
    var data = forecast.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return ForecastModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> deleteForecast(String id) async {
    await forecasts.doc(id).delete();
  }

  Stream<List<ForecastModel>> streamForecasts(String branchId) {
    return forecasts
        .where('branchId', isEqualTo: branchId)
        .orderBy('targetDate', descending: false)
        .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ForecastModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
