import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HeatMapWidget extends StatelessWidget {
  const HeatMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy locations for the heat map (Latitude, Longitude, PriceScore)
    // In a real app, these would come from your Python backend!
    final List<Map<String, dynamic>> locations = [
      {"loc": const LatLng(8.7139, 77.7567), "price": "high"},  // Tirunelveli Center
      {"loc": const LatLng(8.7200, 77.7600), "price": "medium"},
      {"loc": const LatLng(8.7100, 77.7500), "price": "low"},
      {"loc": const LatLng(8.7250, 77.7400), "price": "high"},
      {"loc": const LatLng(8.7050, 77.7700), "price": "low"},
    ];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      // ClipRRect ensures the map stays inside the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(8.7139, 77.7567), // Centered on Tirunelveli
            initialZoom: 13.0,
          ),
          children: [
            // 1. The Map Tiles (The actual visual map)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.estateiq',
            ),
            
            // 2. The Markers (The "Heat" dots)
            MarkerLayer(
              markers: locations.map((spot) {
                return Marker(
                  point: spot['loc'],
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: _getColor(spot['price']),
                    size: 40,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to choose color based on price
  Color _getColor(String priceLevel) {
    if (priceLevel == 'high') return Colors.red;
    if (priceLevel == 'medium') return Colors.orange;
    return Colors.green;
  }
}