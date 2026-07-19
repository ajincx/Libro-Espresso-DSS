// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/product_provider.dart';
import 'providers/ingredient_provider.dart';
import 'providers/recipe_provider.dart';
import 'screens/login_screen.dart';
import 'services/master_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // DEVELOPMENT FLAG
  // Set runSeeder = true ONLY when regenerating demo/test data.
  // After the seeder finishes successfully, immediately set this back to false.
  // The application will start normally without modifying Firestore when runSeeder is false.
  bool runSeeder = false;
  
  // ignore: dead_code
  if (runSeeder) {
    print("========== MASTER SEED STARTED ==========");
    await MasterSeeder().runMasterSeed();
    print("========== MASTER SEED FINISHED ==========");
  }
  
  try {
    print('Checking for branch migrations...');
    final bMap = {
      'main branch': 'branch_1', 
      'lipa branch': 'branch_2', 
      'tagaytay branch': 'branch_3', 
      'evo branch': 'branch_4', 
      'vermosa branch': 'branch_5'
    };
    final snap = await FirebaseFirestore.instance.collection('sales').get();
    int count = 0;
    for (var d in snap.docs) {
      String? branch = d.data()['branchID']?.toString().toLowerCase().trim();
      if (branch != null && bMap.containsKey(branch)) {
        await d.reference.update({'branchID': bMap[branch]});
        count++;
      }
    }
    if (count > 0) {
      print('✅ Migrated $count sales records to use correct branch IDs!');
    }
  } catch (e) {
    print('Migration Error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BranchProvider>(
          create: (_) => BranchProvider(),
          update: (_, authProvider, branchProvider) => branchProvider!..update(authProvider),
        ),
        ChangeNotifierProxyProvider<BranchProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, branchProvider, productProvider) => productProvider!..update(branchProvider),
        ),
        ChangeNotifierProxyProvider<BranchProvider, IngredientProvider>(
          create: (_) => IngredientProvider(),
          update: (_, branchProvider, ingredientProvider) => ingredientProvider!..update(branchProvider),
        ),
        ChangeNotifierProxyProvider<BranchProvider, RecipeProvider>(
          create: (_) => RecipeProvider(),
          update: (_, branchProvider, recipeProvider) => recipeProvider!..update(branchProvider),
        ),
      ],
      child: const LibroEspressoApp(),
    ),
  );
}

class LibroEspressoApp extends StatelessWidget {
  const LibroEspressoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libro Espresso DSS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1028),
          background: Colors.white,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
