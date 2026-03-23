import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Workshop Inventory', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. THE SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search parts (e.g. Pulley, Brake)...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. THE LIVE PARTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Matches the 'spareparts' collection from your screenshot
              stream: FirebaseFirestore.instance.collection('spareparts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading database"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // --- SMART CASE-INSENSITIVE FILTERING ---
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Looks at the 'part' field from your screenshot
                  final partName = (data['part'] ?? '').toString().toLowerCase();
                  return partName.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No matching parts found."));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    // Mapping fields exactly to your Firestore Screenshot:
                    String partName = data['part'] ?? 'Unknown Part';
                    String carModel = data['car model'] ?? 'All Models';
                    String imageUrl = data['imageUrl'] ?? '';
                    int stockLevel = data['stock'] ?? 0;
                    double price = (data['salePrice'] ?? 0.0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.settings_input_component))
                              : Container(color: Colors.blue[50], width: 50, height: 50, child: const Icon(Icons.build)),
                        ),
                        title: Text(partName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("For: $carModel", style: const TextStyle(fontSize: 12)),
                            Text("RM ${price.toStringAsFixed(2)}", 
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            // Red warning if stock is low
                            color: stockLevel < 10 ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Qty: $stockLevel",
                            style: TextStyle(
                              color: stockLevel < 10 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}