import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/features/Map/presentation/widgets/showDetails.dart';
import 'package:mobile_app/features/Map/presentation/widgets/PulsingMarker.dart';

class MapPage extends StatefulWidget {
  MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  bool show = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // map layer
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(36.68715422835151, 2.8655571824826325),
              initialZoom: 15.0,
            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
              ),

              // Marker layer
              MarkerLayer(
                markers: [
                  Marker(
                    width: 70,
                    height: 70,
                    point: LatLng(36.68715422835151, 2.8655571824826325),
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => showDetails(context),
                      ),
                      child: PulsingMarker()
                    ),
                  ),
                ],
              ),
            ],
          ),

          // seach bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded( 
                      child: TextField(
                        cursorColor: Colors.blue,
                        decoration: InputDecoration(
                          hintText: 'Algiers, Algeria',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                
                    const SizedBox(width: 8),
                
                    ElevatedButton(
                      onPressed: () => setState(() {
                        show = !show; 
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.filter_alt_outlined, color: Colors.blue, size: 22),
                    ), 
                  ],
                ),

                const SizedBox(height: 10),

                show
                ? Container(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, //  IMPORTANT
                          children: [
                            const Text(
                              'Filter by severity',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 10),

                            Wrap( // auto wrap
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildFilterButton('All', Colors.green),
                                _buildFilterButton('Low', Colors.green),
                                _buildFilterButton('Medium', Colors.orange),
                                _buildFilterButton('High', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () => setState(() {
        show = false;
      }),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
