import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:municipality_panel/screens/dashboard_screen.dart'; // For getting user location

class MapScreen extends StatefulWidget {
  final String municipalityId;
  const MapScreen({super.key, required this.municipalityId});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final List<LatLng> _polygonLatLngs = [];
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  bool _isSaving = false;
  bool _showInstructions = true;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
  }

  /// Determines the user's current location
  Future<void> _determineUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _showSnackbar('Failed to get current location: $e');
    }
  }

  /// Adds a marker at the tapped position
  void _addMarker(LatLng position) {
    setState(() {
      final markerId = MarkerId(_polygonLatLngs.length.toString());
      _polygonLatLngs.add(position);
      _markers.add(
        Marker(
          markerId: markerId,
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _updateMarkerPosition(markerId, newPosition);
          },
        ),
      );
      _updatePolygon();
    });
  }

  /// Updates marker position when dragged
  void _updateMarkerPosition(MarkerId markerId, LatLng newPosition) {
    final index = int.parse(markerId.value);
    setState(() {
      _polygonLatLngs[index] = newPosition;
      _updatePolygon();
    });
  }

  /// Updates the polygon with the current markers
  void _updatePolygon() {
    _polygons.clear();
    if (_polygonLatLngs.length > 2) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('municipality_polygon'),
          points: _polygonLatLngs,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
    }
  }

  /// Removes the last marker
  void _undoLastMarker() {
    if (_polygonLatLngs.isNotEmpty) {
      setState(() {
        _polygonLatLngs.removeLast();
        _markers.removeWhere(
          (marker) => marker.markerId.value == (_polygonLatLngs.length).toString(),
        );
        _updatePolygon();
      });
    }
  }

  /// Clears all markers and polygons
  void _clearMapping() {
    setState(() {
      _polygonLatLngs.clear();
      _markers.clear();
      _polygons.clear();
    });
  }

  /// Saves the mapped boundary to Firestore
 /// Saves the mapped boundary to Firestore and navigates to the dashboard
/// Saves the mapped boundary to Firestore
/// 
Future<void> _saveMunicipalityBoundary() async {
  if (_polygonLatLngs.isEmpty) {
    _showSnackbar('Please map the boundary first.');
    return;
  }

  setState(() {
    _isSaving = true;
  });

  // Convert polygon points to a storable format
  final boundaryData = _polygonLatLngs
      .map((latLng) => {'latitude': latLng.latitude, 'longitude': latLng.longitude})
      .toList();

  try {
    // Save boundary to Firestore for the fixed municipality
    const String fixedMunicipalityId = "1234567";
    await FirebaseFirestore.instance.collection('Municipalities').doc(fixedMunicipalityId).update({
      'boundary': boundaryData,
    });

    _showSnackbar('Boundary saved successfully!');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  } catch (e) {
    _showSnackbar('Failed to save boundary: $e');
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}


  /// Shows a snackbar with a message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simplified Municipality Mapping'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMunicipalityBoundary,
            ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastMarker,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearMapping,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!, // Center map to user's location
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              polygons: _polygons,
              markers: _markers,
              onTap: _addMarker,
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_showInstructions)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Tap on the map to add points.\n'
                        '2. Drag points to adjust their position.\n'
                        '3. Use the undo button to remove the last point.\n'
                        '4. Save the polygon once complete.',
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _showInstructions = false),
                        child: const Text('Got it!'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
