import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_places_flutter/google_places_flutter.dart' as plac;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_google_maps_webservices/places.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  loc.Location location = loc.Location();
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool isDarkMode = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final userLocation = await location.getLocation();
    setState(() {
      _currentPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
    });

    if (mounted) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _selectedAddress = null;
    });

    List<geo.Placemark> placemarks =
    await geo.placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      setState(() {
        _selectedAddress = placemarks.first.street ?? "Unknown Location";
      });
    }

    mapController.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _onPlaceSelected(String placeId) async {
    final places = GoogleMapsPlaces(apiKey: "AIzaSyDguKHUXspNVB_08ZF2jpSZFnj8tYxXuyU");

    final response = await places.getDetailsByPlaceId(placeId); // ✅ FIXED FUNCTION

    if (response.status == "OK" && response.result.geometry != null) {
      final lat = response.result.geometry!.location.lat;
      final lng = response.result.geometry!.location.lng;
      LatLng selectedLatLng = LatLng(lat, lng);

      setState(() {
        _selectedLocation = selectedLatLng;
        _selectedAddress = response.result.name;
      });

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLatLng, 15.0),
      );
    } else {
      print("Error fetching place details: ${response.errorMessage}");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onTap: _onMapTapped,
            markers: _selectedLocation != null
                ? {
              Marker(
                markerId: MarkerId("selected-location"),
                position: _selectedLocation!,
              ),
            }
                : {},
          ),

          // Search Bar with Suggestions
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: plac.GooglePlaceAutoCompleteTextField(
              textEditingController: searchController,
              googleAPIKey: "AIzaSyDguKHUXspNVB_08ZF2jpSZFnj8tYxXuyU",
              inputDecoration: InputDecoration(
                hintText: "Search Location...",
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              debounceTime: 400,
              isLatLngRequired: false,
              getPlaceDetailWithLatLng: (placeDetail) {
                _onPlaceSelected(placeDetail.placeId!);
              },
              itemClick: (prediction) {
                searchController.text = prediction.description!;
                _onPlaceSelected(prediction.placeId!);
              },
            ),
          ),

          // Floating Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 15,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  heroTag: "my_location",
                  child: Icon(Icons.my_location, color: Colors.white),
                  onPressed: _getUserLocation,
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: Colors.black87,
                  heroTag: "dark_mode",
                  child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isDarkMode = !isDarkMode;
                    });
                    mapController.setMapStyle(isDarkMode ? _darkMapStyle : null);
                  },
                ),
              ],
            ),
          ),

          // Bottom Sheet for Selected Location
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Selected Location",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _selectedAddress ?? "Fetching address...",
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(Icons.check),
                      label: Text("Confirm Location"),
                      onPressed: () {
                        Navigator.pop(context, _selectedLocation);
                      },
                    ),
                  ],
                ),
              ).animate().fade(duration: 300.ms).moveY(begin: 20, end: 0, curve: Curves.easeOut),
            ),
        ],
      ),
    );
  }
}

// Dark Mode Map Style JSON
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#212121" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#757575" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#212121" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "color": "#383838" }
    ]
  }
]
''';
