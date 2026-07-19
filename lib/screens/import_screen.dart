// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart' as csvPkg;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_widgets/bottom_nav.dart';

enum ImportStage { pick, processing, preview, importing, success }

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  ImportStage _stage = ImportStage.pick;
  String? _selectedFileName;
  List<int>? _fileBytes;
  
  String _detectedCollection = '';
  List<String> _columns = [];
  List<List<dynamic>> _previewData = [];
  double _importProgress = 0.0;

  Future<void> _openFilePicker() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xls', 'xlsx', 'csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _fileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _processFile() async {
    if (_fileBytes == null || _selectedFileName == null) return;
    setState(() => _stage = ImportStage.processing);
    
    // Artificial delay to show loading state elegantly
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      String ext = _selectedFileName!.split('.').last.toLowerCase();
      List<List<dynamic>> rows = [];
      
      if (ext == 'csv') {
        String csvString = utf8.decode(_fileBytes!);
        rows = csvPkg.Csv().decode(csvString);
      } else if (ext == 'xls' || ext == 'xlsx') {
        var excel = Excel.decodeBytes(_fileBytes!);
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            rows.add(row.map((e) => e?.value).toList());
          }
          break; // Only read first sheet
        }
      }
      
      if (rows.isEmpty || rows.length < 2) {
        throw Exception("Invalid Excel format. File is empty or missing data rows.");
      }
      
      _columns = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      _previewData = rows.skip(1).toList();
      
      _detectedCollection = 'sales';
      
      setState(() => _stage = ImportStage.preview);
    } catch (e) {
      setState(() => _stage = ImportStage.pick);
      // Clean string message if it's our own exception
      String msg = e.toString().replaceAll('Exception: ', '');
      _showError(msg);
    }
  }

  Future<void> _importToFirestore() async {
    setState(() {
      _stage = ImportStage.importing;
      _importProgress = 0.0;
    });
    
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();
      int skipped = 0;
      
      Map<String, String> branchMap = {
        'main branch': 'branch_1',
        'lipa branch': 'branch_2',
        'tagaytay branch': 'branch_3',
        'evo branch': 'branch_4',
        'vermosa branch': 'branch_5',
      };

      Map<String, String> productMap = {};
      Map<String, double> productCostMap = {};
      var prodsSnap = await firestore.collection('products').get();
      for (var p in prodsSnap.docs) {
        String pName = p.data()['productName']?.toString().toLowerCase().trim() ?? '';
        productMap[pName] = p.id;
        productCostMap[p.id] = double.tryParse(p.data()['cost']?.toString() ?? '0') ?? 0.0;
      }
      
      Map<String, Map<String, dynamic>> groupedSales = {};

      for (int i = 0; i < _previewData.length; i++) {
        try {
          var row = _previewData[i];
          if (row.isEmpty || row[0] == null) {
            skipped++;
            continue;
          }
          
          bool rowFailed = false;
          Map<String, dynamic> rawData = {};
          
          for (int c = 0; c < _columns.length; c++) {
            if (c < row.length) {
              dynamic val = row[c];
              String colName = _columns[c].toLowerCase();
              
              if (val != null) {
                String typeStr = val.runtimeType.toString();
                
                if (typeStr == 'DateCellValue' || typeStr == 'DateTimeCellValue') {
                  try {
                    DateTime dt = DateTime((val as dynamic).year, (val as dynamic).month, (val as dynamic).day);
                    val = Timestamp.fromDate(dt);
                  } catch (e) {
                    rowFailed = true;
                  }
                } else if (typeStr.endsWith('CellValue')) {
                  try { val = (val as dynamic).value; } catch (_) {}
                }
                
                String currentTypeStr = val?.runtimeType.toString() ?? 'null';
                if (val != null && (currentTypeStr == 'TextSpan' || currentTypeStr == 'RichText' || currentTypeStr == 'Text')) {
                  try { val = (val as dynamic).text ?? (val as dynamic).toPlainText(); } catch (_) { val = val.toString(); }
                }
                
                if (val is String && (colName.contains('date') || colName.contains('time'))) {
                  DateTime? parsed = DateTime.tryParse(val);
                  if (parsed != null) val = Timestamp.fromDate(parsed);
                  else rowFailed = true;
                }
                
                if (val != null && !(val is String || val is int || val is double || val is bool || val is Timestamp)) {
                  val = val.toString();
                }
              }
              rawData[_columns[c]] = val;
            }
          }
          
          if (rowFailed) {
            skipped++;
            continue;
          }
          
          var rDataLower = rawData.map((k, v) => MapEntry(k.toLowerCase(), v));
          
          dynamic tsRaw = rDataLower['date'] ?? rDataLower['timestamp'] ?? rDataLower['salesdate'];
          DateTime? tDate;
          if (tsRaw is Timestamp) tDate = tsRaw.toDate();
          else if (tsRaw is DateTime) tDate = tsRaw;
          else if (tsRaw is String) tDate = DateTime.tryParse(tsRaw);
          
          if (tDate == null) {
            skipped++;
            continue;
          }
          
          String year = tDate.year.toString();
          String month = tDate.month.toString().padLeft(2, '0');
          String day = tDate.day.toString().padLeft(2, '0');
          String saleID = 'sale_${year}_${month}_$day';

          String branchNameRaw = rDataLower['branch']?.toString().trim() ?? '';
          String bID = branchMap[branchNameRaw.toLowerCase()] ?? branchNameRaw;
          
          String pNameRaw = rDataLower['product']?.toString().trim() ?? 'Imported Product';
          String pID = productMap[pNameRaw.toLowerCase()] ?? 'unknown_prod';
          
          String cat = rDataLower['category']?.toString().trim() ?? 'Other';
          int qty = int.tryParse(rDataLower['qty']?.toString() ?? rDataLower['quantity']?.toString() ?? '1') ?? 1;
          
          double uPrice = 0;
          if (rDataLower.containsKey('unit price')) uPrice = double.tryParse(rDataLower['unit price'].toString()) ?? 0;
          else if (rDataLower.containsKey('unitprice')) uPrice = double.tryParse(rDataLower['unitprice'].toString()) ?? 0;
          
          double pCost = productCostMap[pID] ?? 0.0;
          double totalPrice = double.parse((qty * uPrice).toStringAsFixed(2));
          double itemCost = double.parse((qty * pCost).toStringAsFixed(2));

          Map<String, dynamic> item = {
            'category': cat,
            'productID': pID,
            'productName': pNameRaw,
            'quantity': qty,
            'unitPrice': double.parse(uPrice.toStringAsFixed(2)),
            'totalPrice': totalPrice,
          };

          if (groupedSales.containsKey(saleID)) {
             groupedSales[saleID]!['items'].add(item);
             double newTotAmt = (groupedSales[saleID]!['totalAmount'] as double) + totalPrice;
             double newTotCost = (groupedSales[saleID]!['cost'] as double) + itemCost;
             double newGrossProfit = newTotAmt - newTotCost;
             if (newGrossProfit < 0 && newTotAmt > newTotCost) newGrossProfit = 0; // "Ensure grossProfit is never negative unless the actual total cost exceeds the total sales amount." => naturally handled by standard math!
             groupedSales[saleID]!['totalAmount'] = double.parse(newTotAmt.toStringAsFixed(2));
             groupedSales[saleID]!['cost'] = double.parse(newTotCost.toStringAsFixed(2));
             groupedSales[saleID]!['grossProfit'] = double.parse(newGrossProfit.toStringAsFixed(2));
          } else {
             double docGrossProfit = totalPrice - itemCost;
             groupedSales[saleID] = {
                 'saleID': saleID,
                 'timestamp': Timestamp.fromDate(DateTime(tDate.year, tDate.month, tDate.day)),
                 'branchID': bID,
                 'totalAmount': totalPrice,
                 'cost': itemCost,
                 'grossProfit': docGrossProfit,
                 'items': [item]
             };
          }
          
        } catch (rowEx) {
          skipped++;
        }
      }
      
      void validateFirestoreData(Map<String, dynamic> payload) {
        for (var entry in payload.entries) {
          var v = entry.value;
          if (v != null && !(v is String || v is int || v is double || v is bool || v is Timestamp || v is List || v is Map || v is FieldValue)) {
            throw Exception("Unsupported field value: a custom ${v.runtimeType} object found in field ${entry.key}.");
          }
          if (v is List) {
            for (var item in v) {
              if (item != null && !(item is String || item is int || item is double || item is bool || item is Timestamp || item is List || item is Map || item is FieldValue)) {
                throw Exception("Unsupported object '${item.runtimeType}' found in list inside field '${entry.key}'.");
              }
              if (item is Map) validateFirestoreData(item as Map<String, dynamic>);
            }
          } else if (v is Map) {
            validateFirestoreData(v as Map<String, dynamic>);
          }
        }
      }
      
      // --- CALCULATION PHASE FOR INVENTORY DEDUCTIONS ---
      Map<String, double> inventoryDeductions = {};
      try {
        var productsSnap = await firestore.collection('products').get();
        Map<String, List<dynamic>> productRecipes = {};
        for (var p in productsSnap.docs) {
          productRecipes[p.id] = (p.data()['recipe'] as List<dynamic>?) ?? [];
        }
        
        for (var entry in groupedSales.entries) {
          String saleID = entry.key;
          print('\n--- Processing Sales Document ID: $saleID ---');
          var newSaleData = entry.value;
          List<dynamic> newItems = newSaleData['items'] ?? [];
          print('Number of items found: ${newItems.length}');
          
          Map<String, double> oldUsage = {};
          var existingSale = await firestore.collection('sales').doc(saleID).get();
          if (existingSale.exists) {
            List<dynamic> oldItems = existingSale.data()?['items'] ?? [];
            for (var item in oldItems) {
              String pID = item['productID'] ?? '';
              int qty = (item['quantity'] as num?)?.toInt() ?? 0;
              List<dynamic> recipe = productRecipes[pID] ?? [];
              for (var ing in recipe) {
                String invID = ing['inventoryID'] ?? '';
                double reqQty = (ing['quantity'] as num?)?.toDouble() ?? 0.0;
                if (invID.isNotEmpty && reqQty > 0) {
                  oldUsage[invID] = (oldUsage[invID] ?? 0.0) + (reqQty * qty);
                }
              }
            }
          }
          
          Map<String, double> newUsage = {};
          for (var item in newItems) {
            String pID = item['productID'] ?? '';
            int qty = (item['quantity'] as num?)?.toInt() ?? 0;
            print('-> Checking productID: $pID | sold quantity: $qty');
            
            bool productFound = productRecipes.containsKey(pID);
            print('Product found: $productFound');
            if (!productFound) {
              print('Product not found');
              continue;
            }
            
            List<dynamic> recipe = productRecipes[pID] ?? [];
            print('Number of recipe ingredients: ${recipe.length}');
            if (recipe.isEmpty) {
              print('Recipe empty');
              continue;
            }

            for (var ing in recipe) {
              String invID = ing['inventoryID'] ?? '';
              double reqQty = (ing['quantity'] as num?)?.toDouble() ?? 0.0;
              if (invID.isNotEmpty && reqQty > 0) {
                newUsage[invID] = (newUsage[invID] ?? 0.0) + (reqQty * qty);
              }
            }
          }
          
          Set<String> allInvIDs = {...oldUsage.keys, ...newUsage.keys};
          for (String invID in allInvIDs) {
            double netDeduct = (newUsage[invID] ?? 0.0) - (oldUsage[invID] ?? 0.0);
            if (netDeduct != 0) {
              inventoryDeductions[invID] = (inventoryDeductions[invID] ?? 0.0) + netDeduct;
            }
          }
        }
      } catch (e) {
        print('Error calculating inventory deductions: $e');
      }
      // --- END CALCULATION PHASE ---

      int count = 0;
      int totalDocs = groupedSales.length;
      String lastImportedSaleID = '';

      for (var entry in groupedSales.entries) {
        var data = entry.value;
        // Gross profit is already precisely calculated and aggregated inside groupedSales mapping.
        
        lastImportedSaleID = entry.key;
        var docRef = firestore.collection('sales').doc(entry.key);
        
        validateFirestoreData(data);
        batch.set(docRef, data);
        
        count++;
        if (count % 100 == 0) {
          setState(() => _importProgress = count / (totalDocs == 0 ? 1 : totalDocs));
          await batch.commit();
          batch = firestore.batch();
        }
      }
      
      if (count % 100 != 0) {
        await batch.commit();
      }
      
      // --- COMMIT INVENTORY DEDUCTIONS ---
      if (inventoryDeductions.isNotEmpty) {
        print('Applying inventory deductions...');
        WriteBatch invBatch = firestore.batch();
        int invCount = 0;
        
        for (var entry in inventoryDeductions.entries) {
          String invID = entry.key;
          double deductAmt = entry.value;
          if (deductAmt == 0) continue;
          
          var invRef = firestore.collection('inventory').doc(invID);
          var invSnap = await invRef.get();
          
          print('--- Committing Inventory: $invID ---');
          if (invSnap.exists) {
            num? expectedStockVal = invSnap.data()?['expectedStock'] as num?;
            double currentExpected = expectedStockVal != null ? expectedStockVal.toDouble() : ((invSnap.data()?['stock'] as num?)?.toDouble() ?? 0.0);
            double reorderLevel = (invSnap.data()?['reorderLevel'] as num?)?.toDouble() ?? 20.0;
            
            double newExpected = currentExpected - deductAmt;
            
            print('inventoryID: $invID');
            print('Current expectedStock: $currentExpected');
            print('Deduction: $deductAmt');
            print('Updated expectedStock: $newExpected');
            
            String newStatus = 'Active';
            if (newExpected <= 0) {
              newStatus = 'Out of Stock';
            } else if (newExpected <= reorderLevel) {
              newStatus = 'Low Stock';
            }
            
            invBatch.update(invRef, {
              'expectedStock': newExpected,
              'status': newStatus,
            });
            
            invCount++;
            if (invCount % 100 == 0) {
              await invBatch.commit();
              invBatch = firestore.batch();
            }
          } else {
            print('Inventory not found');
            print('inventoryID: $invID (Skipped)');
          }
        }
        
        if (invCount % 100 != 0) {
          await invBatch.commit();
        }
        print('Inventory updated successfully.');
      }
      // --- END COMMIT INVENTORY ---

      print('Import finished successfully.');
      print('Collection written:\nsales');
      print('Documents imported:\n$count');
      print('Last imported document:\n$lastImportedSaleID');
      
      final snapshot = await FirebaseFirestore.instance.collection('sales').get();
      print('Sales collection now contains:\n${snapshot.docs.length} documents');
      
      setState(() {
        _importProgress = 1.0;
        _stage = ImportStage.success;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported successfully: $count documents\nSkipped: $skipped rows'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() => _stage = ImportStage.preview);
      _showError("Error importing data: $e");
    }
  }

  void _reset() {
    setState(() {
      _stage = ImportStage.pick;
      _selectedFileName = null;
      _fileBytes = null;
      _columns = [];
      _previewData = [];
      _detectedCollection = '';
      _importProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Import Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_stage == ImportStage.preview || _stage == ImportStage.success)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _reset,
            )
        ],
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
      floatingActionButton: const ImportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const DashboardBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildBodyContent() {
    if (_stage == ImportStage.processing || _stage == ImportStage.importing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFF6A1028),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _stage == ImportStage.processing ? 'Parsing File...' : 'Saving to $_detectedCollection...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF6A1028)),
            ),
            if (_stage == ImportStage.importing) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _importProgress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: const Color(0xFF6A1028),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(_importProgress * 100).toInt()}%',
                style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
            ]
          ],
        ),
      );
    }

    if (_stage == ImportStage.success) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 72),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Complete!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully added to $_detectedCollection',
              style: const TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1028).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text(
                  'Import Another File',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_stage == ImportStage.preview) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Data Preview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Color(0xFF1F2937)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)]),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _detectedCollection,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Poppins'),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Found ${_previewData.length} valid rows.',
                  style: const TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF6A1028).withValues(alpha: 0.06)),
                            columns: _columns.map((col) => DataColumn(
                              label: Text(
                                col.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Poppins', color: Color(0xFF6A1028)),
                              ),
                            )).toList(),
                            rows: _previewData.take(20).map((row) {
                              return DataRow(
                                cells: _columns.map((col) {
                                  int index = _columns.indexOf(col);
                                  String val = index < row.length ? row[index].toString() : '';
                                  return DataCell(Text(val, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Color(0xFF1F2937))));
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_previewData.length > 20)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text(
                        'Showing first 20 rows only.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1028).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _importToFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                    label: const Text(
                      'Confirm Import to Firestore',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }
      );
    }

    // Default stage: pick
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _openFilePicker,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8F5),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                  border: Border.all(
                    color: _selectedFileName != null
                        ? const Color(0xFF6A1028)
                        : const Color(0xFFD4A853),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _selectedFileName != null
                            ? const Color(0xFF6A1028).withValues(alpha: 0.08)
                            : const Color(0xFFD4A853).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedFileName != null ? Icons.insert_drive_file_outlined : Icons.cloud_upload_outlined,
                        size: 56,
                        color: _selectedFileName != null ? const Color(0xFF6A1028) : const Color(0xFFD4A853),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _selectedFileName ?? 'Tap to browse Excel/CSV',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedFileName != null ? const Color(0xFF1F2937) : const Color(0xFF6A1028),
                      ),
                    ),
                    if (_selectedFileName == null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Supported formats: .xls, .xlsx, .csv',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFileName != null)
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A1028).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _processFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.preview_outlined, color: Colors.white),
                  label: const Text(
                    'Parse & Preview',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
