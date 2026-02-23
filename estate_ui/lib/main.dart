import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:http/http.dart' as http;
import 'map_screen.dart';    

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EstateIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const EstateDashboard(),
    );
  }
}

class EstateDashboard extends StatefulWidget {
  const EstateDashboard({super.key});

  @override
  State<EstateDashboard> createState() => _EstateDashboardState();
}

class _EstateDashboardState extends State<EstateDashboard> {
  // Inputs
  final TextEditingController sqFtController = TextEditingController();
  final TextEditingController bedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  
  // State
  String currMarket = "₹0 L";
  String currAsset = "₹0 L";
  String futMarket = "₹0 L";
  String futAsset = "₹0 L";
  
  bool isLoading = false;
  double selectedYear = 2026; 

  // Data
  List<dynamic> allProperties = []; 
  List<String> cities = [];
  List<String> locations = [];
  String? selectedCity;
  String? selectedLocation;

  @override
  void initState() {
    super.initState();
    fetchProperties(); 
  }

  String _formatCurrency(String rawValue) {
    double? val = double.tryParse(rawValue);
    if (val == null) return "₹0 L";
    if (val >= 100) {
      double cr = val / 100;
      String crStr = cr.toStringAsFixed(2).replaceAll(RegExp(r"([.]*00)(?!.*\d)"), "");
      return "₹$crStr Cr";
    } else {
      String lStr = val.toStringAsFixed(2).replaceAll(RegExp(r"([.]*00)(?!.*\d)"), "");
      return "₹$lStr L";
    }
  }

  Future<void> fetchProperties() async {
    // ⚠️ USE 10.0.2.2 FOR ANDROID EMULATOR / 127.0.0.1 FOR WEB
    const String apiUrl = "http://127.0.0.1:8000/all_properties"; 
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Set<String> citySet = {};
        for (var item in data) {
          if (item['city'] != null) citySet.add(item['city'].toString());
        }
        setState(() {
          allProperties = data;
          cities = citySet.toList()..sort();
          if (cities.isNotEmpty) {
            selectedCity = cities.first;
            _updateLocationsForCity(selectedCity!);
          }
        });
      }
    } catch (e) {
      print("Error fetching properties: $e");
    }
  }

  void _updateLocationsForCity(String city) {
    final Set<String> locSet = {};
    for (var item in allProperties) {
      if (item['city'] == city && item['location'] != null) {
        locSet.add(item['location'].toString());
      }
    }
    setState(() {
      locations = locSet.toList()..sort();
      selectedLocation = locations.isNotEmpty ? locations.first : null;
    });
  }

  Future<void> getPrediction() async {
    if (selectedLocation == null) return;
    setState(() => isLoading = true);
    
    // ⚠️ USE 10.0.2.2 FOR ANDROID EMULATOR / 127.0.0.1 FOR WEB
    const String apiUrl = "http://127.0.0.1:8000/predict_price"; 

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "area": int.tryParse(sqFtController.text) ?? 1000,
          "bhk": int.tryParse(bedController.text) ?? 2,
          "bathroom": 2, 
          "age": int.tryParse(ageController.text) ?? 0,
          "location": selectedLocation, 
          "status": "Ready to move",
          "target_year": selectedYear.toInt() 
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currMarket = _formatCurrency(data['current_market'].toString());
          currAsset = _formatCurrency(data['current_asset'].toString());
          futMarket = _formatCurrency(data['future_market'].toString());
          futAsset = _formatCurrency(data['future_asset'].toString());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Failed")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openFilteredMap() {
    if (selectedLocation == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          locationName: selectedLocation!, 
          cityName: selectedCity ?? "Chennai",
          price: currMarket.replaceAll("₹", "") 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("EstateIQ Analytics", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 25),

              // --- QUAD INFO CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    Text("Valuation Analysis", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    
                    isLoading 
                     ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white)))
                     : Column(
                        children: [
                          // ROW 1: TODAY (2026)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildValueBlock("TODAY'S MARKET", currMarket, Colors.white, "Based on Demand"),
                              Container(width: 1, height: 35, color: Colors.white24),
                              _buildValueBlock("TODAY'S ASSET", currAsset, Colors.white70, "Depreciated Value"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(height: 1, width: double.infinity, color: Colors.white12), // Divider
                          const SizedBox(height: 20),
                          
                          // ROW 2: FUTURE (Target Year)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildValueBlock("FUTURE MARKET", futMarket, const Color(0xFF4ADE80), "Year ${selectedYear.toInt()}"), // Green
                              Container(width: 1, height: 35, color: Colors.white24),
                              _buildValueBlock("FUTURE ASSET", futAsset, const Color(0xFFFDBA74), "Age + Wait"), // Orange
                            ],
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 25),
                    
                    // SLIDER
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Projection Timeline: ${selectedYear.toInt()}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFFFDBA74),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: selectedYear,
                            min: 2026, max: 2036, divisions: 10,
                            onChanged: (val) => setState(() => selectedYear = val),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- INPUT FORM ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _inputField(sqFtController, "Area (Sq Ft)", Icons.square_foot),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _inputField(bedController, "BHK", Icons.bed)),
                        const SizedBox(width: 15),
                        Expanded(child: _inputField(ageController, "Current Age", Icons.history)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      isExpanded: true,
                      decoration: _inputDeco("Select City", Icons.location_city),
                      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() { selectedCity = val; _updateLocationsForCity(val!); });
                      },
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      decoration: _inputDeco("Select Area", Icons.map),
                      items: locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) => setState(() => selectedLocation = val),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: getPrediction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1E1E), 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Run Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 55, width: 55,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: openFilteredMap, 
                            icon: const Icon(Icons.map_outlined, color: Color(0xFF2563EB)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueBlock(String label, String value, Color color, String subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(subtext, style: GoogleFonts.poppins(color: Colors.white24, fontSize: 9)),
      ],
    );
  }

  Widget _inputField(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: _inputDeco(label, icon),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }
}