import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/bloc/index.dart';
import 'package:mobile_app/models/index.dart';
import 'package:mobile_app/features/Map/presentation/widgets/showDetails.dart';
import 'package:mobile_app/features/Map/presentation/widgets/PulsingMarker.dart';

class MapPage extends StatefulWidget {
  MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const LatLng _defaultCenter = LatLng(
    36.68715422835151,
    2.8655571824826325,
  );

  bool show = false;
  String selectedSeverity = 'All';

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(
      const ReportsFetchNearbyEvent(
        latitude: 36.68715422835151,
        longitude: 2.8655571824826325,
        radiusKm: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = context.watch<ReportsBloc>().state;
    final markers = _buildMarkers(reportsState);

    return Scaffold(
      body: Stack(
        children: [
          // map layer
          FlutterMap(
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 15.0,
            ),
            children: [
              // Map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
              ),

              // Marker layer
              MarkerLayer(markers: markers),
            ],
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(18),
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          child: TextField(
                            cursorColor: Colors.blue,
                            decoration: InputDecoration(
                              hintText: 'Algiers, Algeria',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: Colors.blue,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(16),
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() {
                            show = !show;
                          }),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.filter_alt_outlined,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (show)
                    Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(20),
                      shadowColor: Colors.black.withValues(alpha: 0.10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter by severity',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildFilterButton('All', Colors.grey),
                                _buildFilterButton('Low', Colors.green),
                                _buildFilterButton('Medium', Colors.orange),
                                _buildFilterButton('High', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, Color color) {
    return ElevatedButton(
      onPressed: () => setState(() {
        selectedSeverity = text;
        show = false;
      }),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  List<Marker> _buildMarkers(ReportsState state) {
    final reports = state is NearbyReportsLoaded
        ? state.reports
        : state is ReportsLoaded
        ? state.reports
        : <Report>[];

    final filtered = selectedSeverity == 'All'
        ? reports
        : reports
              .where(
                (report) =>
                    report.severity.value.toLowerCase() ==
                    selectedSeverity.toLowerCase(),
              )
              .toList();

    return filtered
        .map(
          (report) => Marker(
            width: 70,
            height: 70,
            point: LatLng(report.latitude, report.longitude),
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => showDetails(context, report: report),
              ),
              child: PulsingMarker(severity: report.severity.value.toLowerCase()),
            ),
          ),
        )
        .toList();
  }
}