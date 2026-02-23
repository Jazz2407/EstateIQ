import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final String locationName;
  final String cityName; // <--- NEW: Received City Name
  final String price; 

  const MapScreen({
    super.key, 
    required this.locationName, 
    required this.cityName, // <--- Add to constructor
    required this.price
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng center = const LatLng(13.0827, 80.2707); // Default (Chennai)
  bool isLoading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCoordinates();
  }

  String _getFormattedPrice(String rawValue) {
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

  Future<void> _getCoordinates() async {
    // 🔍 SEARCH QUERY: "Location, City" (e.g. "Maharaja Nagar, Tirunelveli")
    final query = "${widget.locationName}, ${widget.cityName}";
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1");
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final newLocation = LatLng(
            double.parse(data[0]['lat']),
            double.parse(data[0]['lon']),
          );

          setState(() {
            center = newLocation;
            isLoading = false;
          });
          
          _mapController.move(newLocation, 13.5);
        } else {
          print("Location not found on map.");
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error finding location: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayPrice = _getFormattedPrice(widget.price);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.locationName}, ${widget.cityName}"), // Show full address
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center, 
              initialZoom: 13.0,     
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    color: Colors.blueAccent.withOpacity(0.3),
                    borderColor: Colors.blueAccent,
                    borderStrokeWidth: 2,
                    radius: 1200, 
                    useRadiusInMeter: true, 
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Estimated Market Value", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(displayPrice, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 5),
                    Text("📍 ${widget.locationName}", style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}