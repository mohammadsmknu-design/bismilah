import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(const WifiAnalyzerApp());
}

class WifiAnalyzerApp extends StatelessWidget {
  const WifiAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.cyanAccent,
      ),
      home: const WifiHomeScreen(),
    );
  }
}

class WifiHomeScreen extends StatefulWidget {
  const WifiHomeScreen({super.key});

  @override
  State<WifiHomeScreen> createState() => _WifiHomeScreenState();
}

class _WifiHomeScreenState extends State<WifiHomeScreen> {
  final info = NetworkInfo();
  
  String? _ssid = "Unknown";
  String? _ip = "0.0.0.0";
  String? _bssid = "00:00:00:00:00";

  @override
  void initState() {
    super.initState();
    _fetchNetworkData();
  }

  Future<void> _fetchNetworkData() async {
    final ssid = await info.getWifiName();
    final ip = await info.getWifiIP();
    final bssid = await info.getWifiBSSID();

    setState(() {
      _ssid = ssid ?? "Tidak Terhubung";
      _ip = ip ?? "Unknown IP";
      _bssid = bssid ?? "Unknown BSSID";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("WIFI ANALYZER PRO"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Card Utama untuk SSID
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.wifi, size: 60, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(_ssid!, 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("Current Connection", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Detail Informasi
            _buildDetailCard("IP Address", _ip!, Icons.lan),
            _buildDetailCard("BSSID", _bssid!, Icons.fingerprint),
            
            const Spacer(),
            
            // Tombol Refresh
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _fetchNetworkData,
                icon: const Icon(Icons.refresh),
                label: const Text("REFRESH NETWORK"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(top: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}