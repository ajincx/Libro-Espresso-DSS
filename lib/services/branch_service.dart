// ignore_for_file: unused_import, unused_field
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/branch_model.dart';
import '../models/user_model.dart';

class BranchService extends FirestoreService {
  BranchService({super.firestore});

  Future<void> addBranch(BranchModel branch) async {}
  Future<void> updateBranch(String id, Map<String, dynamic> updates) async {}
  Future<void> deleteBranch(String id) async {}
  Future<BranchModel?> getBranchById(String id) async => null;
  Future<List<BranchModel>> getBranches() async => [];
  Future<List<BranchModel>> getActiveBranches() async => [];
  Future<List<BranchModel>> searchBranches(String query) async => [];
  Stream<List<BranchModel>> streamBranches() => Stream.value([]);
  Stream<List<BranchModel>> streamActiveBranches() => Stream.value([]);
  Future<List<UserModel>> getManagersByBranch(String branchId) async => [];
  Future<void> assignManagerToBranch(String managerUid, String branchId) async {}
  Future<void> reassignManager(String managerUid, String newBranchId) async {}
  Future<void> removeManagerFromBranch(String managerUid) async {}
}

