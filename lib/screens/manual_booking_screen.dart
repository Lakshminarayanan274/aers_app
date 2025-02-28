import 'dart:io';
import 'package:aers_app/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

class ManualBookingScreen extends StatefulWidget {
  @override
  _ManualBookingScreenState createState() => _ManualBookingScreenState();
}

class _ManualBookingScreenState extends State<ManualBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  LatLng? _selectedLocation;
  String? _locationName;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  List<Map<String, dynamic>> bookingHistory = [];
  File? _selectedImage;
  String? _userID;

  @override
  void initState() {
    super.initState();
    _fetchUserID();
    _fetchBookingHistory();
  }

  void _fetchUserID() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userID = user.uid;
      });
      debugPrint("User ID fetched: $_userID");
    } else {
      debugPrint("Error: No user logged in.");
    }
  }

  Future<void> _navigateToMapScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
      });
      debugPrint("Location selected: $_selectedLocation");
      _fetchLocationName(result.latitude, result.longitude);
    } else {
      debugPrint("Error: No location returned from map screen.");
    }
  }


  Future<void> _fetchLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _locationName =
          "${place.street}, ${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          _locationName = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        _locationName = "Unknown location";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      debugPrint("Submitting booking...");

      if (_selectedLocation == null) {
        debugPrint("Error: No location selected.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please select a location before submitting."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_userID == null) {
        debugPrint("Error: User ID is null.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: User not logged in."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_detailsController.text
          .trim()
          .isEmpty) {
        debugPrint("Error: Emergency details are empty.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter emergency details."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final DatabaseReference databaseRef =
        FirebaseDatabase.instance.ref().child('Bookings').push();

        await databaseRef.set({
          'Name':_nameController.text,
          'userID': _userID!,
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'locname': _locationName ?? "Unknown Location",
          },
          'timestamp': ServerValue.timestamp,
          'details': _detailsController.text,
          'status': 'pending',
        });

        debugPrint("Booking submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        _nameController.clear();
        _contactController.clear();
        _detailsController.clear();
        setState(() {
          _selectedLocation = null;
          _locationName = null;
          _selectedImage = null;
        });

        _fetchBookingHistory();
      } catch (e) {
        debugPrint("Error submitting booking: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting booking: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _fetchBookingHistory() async {
    if (_userID == null) return;

    final DatabaseReference bookingRef =
    FirebaseDatabase.instance.ref().child('Bookings');
    final snapshot = await bookingRef.get();

    if (snapshot.exists) {
      final bookingsData = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        bookingHistory = bookingsData.values
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .where((booking) => booking['userID'] == _userID)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userID == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1A1F36), // Dark Blue Background
      appBar: AppBar(
        title: Text(
          "Manual Booking",
          style: TextStyle(color: Colors.white), // **White Text**
        ),
        backgroundColor: Color(0xFF2A2D48), // Darker Blue Shade
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Full Name", Icons.person, _nameController, isRequired: true),
              _buildTextField("Contact Number", Icons.phone, _contactController, isRequired: true, isPhoneNumber: true),
              _buildTextField("Emergency Details", Icons.description, _detailsController, isMultiline: true, isRequired: true),

              SizedBox(height: 10),
              _buildCard("Select Accident Location", Icons.map, _locationName ?? "Tap to select", _navigateToMapScreen),
              _buildCard("Attach Image", Icons.camera_alt, "Tap to upload", _pickImage),

              if (_selectedImage != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(_selectedImage!, height: 150),
                ),

              SizedBox(height: 15),
              ElevatedButton(
                onPressed: _submitBooking,
                child: Text("Submit Booking"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4850A8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),


              SizedBox(height: 20),

              Text(
                "Booking History",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: bookingHistory.length,
                itemBuilder: (context, index) {
                  final booking = bookingHistory[index];
                  return ListTile(
                    title: Text(
                        "Location: ${booking['location']['locname'] ?? 'Unknown'}",
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text("Name: ${booking['Name']} Details:${booking['details']}",
                        style: TextStyle(color: Colors.white70)),
                    trailing: Text("Status: ${booking['status']}",
                        style: TextStyle(color: Colors.greenAccent)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon,
      TextEditingController controller,
      {bool isMultiline = false, bool isRequired = false, bool isPhoneNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        style: TextStyle(color: Colors.white),
        keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white10,
          filled: true,
        ),
        validator: (value) {
          if (isRequired && (value == null || value
              .trim()
              .isEmpty)) {
            return "$label is required";
          }
          if (isPhoneNumber && value!.length < 10) {
            return "Enter a valid phone number";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, String subtitle,
      Function onTap) {
    return Card(
      color: Colors.blueGrey[900],
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white)),
        trailing: Icon(icon, color: Colors.blueAccent),
        onTap: () => onTap(),
      ),
    );
  }
}