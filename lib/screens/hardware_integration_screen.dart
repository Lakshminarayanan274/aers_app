import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HardwareIntegrationScreen extends StatefulWidget {
  @override
  _HardwareIntegrationScreenState createState() => _HardwareIntegrationScreenState();
}

class _HardwareIntegrationScreenState extends State<HardwareIntegrationScreen> {
  bool gpsStatus = false;
  bool communicationStatus = false;
  bool gyroscopeStatus = false;

  bool _showSuccess = true;
  String _statusMessage = "Checking Device Modules..."; // Initial message

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () { // Simulating hardware check
      setState(() {
        gpsStatus = true;
        communicationStatus = true;
        gyroscopeStatus = true;
        _statusMessage = "Device Modules Verified Successfully ✅"; // Update message
      });

      Future.delayed(Duration(seconds: 2), () { // Wait for animation to complete
        setState(() {
          _showSuccess = false; // Stop Lottie animation
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Hardware Status',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Lottie.asset('assets/animations/hardware.json', height: 180),
          SizedBox(height: 10),
          AnimatedSwitcher( // Smooth text transition
            duration: Duration(milliseconds: 500),
            child: Text(
              _statusMessage,
              key: ValueKey(_statusMessage),
              style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                buildStatusCard(
                  title: 'GPS Module',
                  icon: Icons.location_on_rounded,
                  status: gpsStatus,
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 20),
                buildStatusCard(
                  title: 'Communication Module',
                  icon: Icons.signal_cellular_alt,
                  status: communicationStatus,
                  color: Colors.orangeAccent,
                ),
                SizedBox(height: 20),
                buildStatusCard(
                  title: 'Gyroscope',
                  icon: Icons.device_hub_rounded,
                  status: gyroscopeStatus,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard({required String title, required IconData icon, required bool status, required Color color}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: status
                ? (_showSuccess
                ? Lottie.asset('assets/animations/success.json', height: 40, key: ValueKey(true))
                : Icon(Icons.check_circle, color: Colors.green, size: 40))
                : Lottie.asset('assets/animations/error.json', height: 40, key: ValueKey(false)),
          ),
        ],
      ),
    );
  }
}
