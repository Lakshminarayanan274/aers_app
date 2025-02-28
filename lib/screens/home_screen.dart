import 'package:flutter/material.dart';
import 'manual_booking_screen.dart';
import 'hardware_integration_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Makes AppBar blend with the background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'AERS Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // **Updated Background Gradient to a Soft Blue Theme**
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2EBF2), Color(0xFF0288D1)], // **Soft Sky Blue to Deep Blue**
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Column(
            children: [
              SizedBox(height: 100),

              // **Header Text**
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Welcome to AERS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              // **Grid View for Menu Options**
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // **Two cards per row**
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildPremiumCard(context, 'Request Ambulance', Icons.local_hospital_rounded, Colors.redAccent, ManualBookingScreen()),
                    _buildPremiumCard(context, 'Hardware Status', Icons.settings, Colors.blueAccent, HardwareIntegrationScreen()),
                    _buildPremiumCard(context, 'Profile', Icons.person, Colors.green, ProfileScreen()),
                    _buildPremiumCard(context, 'Emergency Contacts', Icons.phone, Colors.orange, ProfileScreen()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // **Custom Animated Glassmorphic Card with Premium Look**
  Widget _buildPremiumCard(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), // Soft transparency
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, spreadRadius: 1),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
