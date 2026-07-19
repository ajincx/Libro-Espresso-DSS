// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';

class MasterSeeder {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> runMasterSeed() async {
    print('========== INVENTORY SEED ==========');
    try {
      final existingInv = await firestore.collection('inventory').get();
      print('Inventory before delete: ${existingInv.docs.length}');
      
      final deleteBatch = firestore.batch();
      for (final doc in existingInv.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      
      print('Deleted old inventory.');

      final existingShrinkages = await firestore.collection('shrinkage').get();
      print('Shrinkages before delete: ${existingShrinkages.docs.length}');
      
      final deleteShrinkagesBatch = firestore.batch();
      for (final doc in existingShrinkages.docs) {
        deleteShrinkagesBatch.delete(doc.reference);
      }
      await deleteShrinkagesBatch.commit();
      
      print('Deleted old shrinkages.');

      final productsDocs = await firestore.collection('products').get();
      Map<String, Map<String, dynamic>> uniqueIngredients = {};

      for (var doc in productsDocs.docs) {
        final data = doc.data();
        if (data.containsKey('recipe')) {
          List<dynamic> recipe = data['recipe'];
          for (var item in recipe) {
            String invId = item['inventoryID'] ?? '';
            String name = item['ingredientName'] ?? '';
            String unit = item['unit'] ?? 'pcs';
            
            if (name.isNotEmpty) {
              if (!uniqueIngredients.containsKey(name)) {
                uniqueIngredients[name] = {
                  'inventoryID': invId,
                  'ingredientName': name,
                  'unit': unit,
                };
              } else {
                // If the ingredient already exists but didn't have an ID, update it if this one does
                if (uniqueIngredients[name]!['inventoryID'] == '' && invId.isNotEmpty) {
                  uniqueIngredients[name]!['inventoryID'] = invId;
                }
              }
            }
          }
        }
      }

      int maxNum = 0;
      for (var data in uniqueIngredients.values) {
        String invId = data['inventoryID'];
        if (invId.startsWith('inv_')) {
          final numStr = invId.substring(4);
          final num = int.tryParse(numStr);
          if (num != null && num > maxNum) maxNum = num;
        }
      }

      int counter = maxNum + 1;
      
      final insertBatch = firestore.batch();
      final Timestamp now = Timestamp.now();

      for (var entry in uniqueIngredients.entries) {
        final name = entry.key;
        final data = entry.value;
        
        String invId = data['inventoryID'];
        if (invId.isEmpty || !invId.startsWith('inv_')) {
          invId = 'inv_${counter.toString().padLeft(2, '0')}';
          counter++;
        }

        double startingStock = 100.0;
        String nLow = name.toLowerCase();
        
        if (nLow.contains('bean') || nLow.contains('espresso')) startingStock = 5000.0;
        else if (nLow.contains('milk')) startingStock = 10000.0;
        else if (nLow.contains('syrup')) startingStock = 3000.0;
        else if (nLow.contains('powder') || nLow.contains('matcha') || nLow.contains('choc')) startingStock = 2000.0;
        else if (nLow.contains('tea')) startingStock = 1500.0;
        else if (nLow.contains('bread') || nLow.contains('croissant') || nLow.contains('muffin') || nLow.contains('dough') || nLow.contains('batter')) startingStock = 100.0;
        else if (data['unit'] == 'g' || data['unit'] == 'ml') startingStock = 3000.0;

        double minStock = startingStock * 0.20;
        
        String status = "In Stock";
        if (startingStock == 0) status = "Out of Stock";
        else if (startingStock <= minStock) status = "Low Stock";

        String category = 'Others';
        if (nLow.contains('bean') || nLow.contains('espresso')) category = 'Coffee';
        else if (nLow.contains('milk')) category = 'Dairy';
        else if (nLow.contains('syrup')) category = 'Syrups';
        else if (nLow.contains('powder') || nLow.contains('matcha') || nLow.contains('choc')) category = 'Powders';
        else if (nLow.contains('tea')) category = 'Tea';
        else if (nLow.contains('bread') || nLow.contains('dough') || nLow.contains('batter') || nLow.contains('muffin') || nLow.contains('croissant')) category = 'Pastry';
        else if (nLow.contains('pasta') || nLow.contains('bacon') || nLow.contains('ham') || nLow.contains('cheese') || nLow.contains('sauce')) category = 'Food';

        final invDoc = {
          'inventoryID': invId,
          'ingredientName': name,
          'category': category,
          'stock': startingStock,
          'expectedStock': startingStock,
          'unit': data['unit'],
          'minimumStock': minStock,
          'status': status,
          'updatedAt': now,
        };

        insertBatch.set(firestore.collection('inventory').doc(invId), invDoc);
        print('Prepared inventory: $invId - $name');
      }

      await insertBatch.commit();
      
      final afterInsertDocs = await firestore.collection('inventory').get();
      print('Inventory after insert: ${afterInsertDocs.docs.length}');
      print('========== INVENTORY SEED FINISHED ==========');
      
      // Branch Seeding
      await _seedBranches();
    } catch (e) {
      print('ERROR: $e');
    }
  }

  Future<void> _seedBranches() async {
    print('========== BRANCHES SEED ==========');
    try {
      final existingBranches = await firestore.collection('branches').get();
      print('Branches before delete: ${existingBranches.docs.length}');
      
      final deleteBatch = firestore.batch();
      for (final doc in existingBranches.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      print('Deleted old branches.');

      final List<Map<String, String>> branchesData = [
        {'id': 'branch_1', 'name': 'Main Branch', 'location': 'Batangas City', 'userID': 'user_mgr_1'},
        {'id': 'branch_2', 'name': 'Lipa Branch', 'location': 'Lipa City', 'userID': 'user_mgr_2'},
        {'id': 'branch_3', 'name': 'Tagaytay Branch', 'location': 'Tagaytay', 'userID': 'user_mgr_3'},
        {'id': 'branch_4', 'name': 'Evo Branch', 'location': 'Cavite', 'userID': 'user_mgr_4'},
        {'id': 'branch_5', 'name': 'Vermosa Branch', 'location': 'Cavite', 'userID': 'user_mgr_5'},
      ];

      final insertBatch = firestore.batch();
      for (final b in branchesData) {
        final docRef = firestore.collection('branches').doc(b['id']);
        insertBatch.set(docRef, {
          'branchID': b['id'],
          'branchName': b['name'],
          'location': b['location'],
          'userID': b['userID'],
        });
      }
      await insertBatch.commit();
      print('========== BRANCHES SEED FINISHED ==========');
    } catch (e) {
      print('ERROR SEEDING BRANCHES: $e');
    }
  }
}
