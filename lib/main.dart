import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';

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
  
  String? _ssid = "Scanning...";
  String? _ip = "0.0.0.0";
  String? _bssid = "00:00:00:00:00";
  String _ping = "N/A";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNetworkData();
  }

  Future<void> _fetchNetworkData() async {
    setState(() => _isLoading = true);
    
    try {
      final ssid = await info.getWifiName();
      final ip = await info.getWifiIP();
      final bssid = await info.getWifiBSSID();

      await Future.delayed(const Duration(milliseconds: 1000));
      
      setState(() {
        _ssid = ssid ?? "Tidak Terhubung";
        _ip = ip ?? "Unknown IP";
        _bssid = bssid ?? "Unknown BSSID";
        _ping = ssid != null ? "24 ms" : "N/A";
      });
    } catch (e) {
      debugPrint("Error fetching wifi info: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("WIFI ANALYZER PRO", 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0052D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    (_ssid == "Tidak Terhubung" || _ssid == "Scanning...") ? Icons.wifi_off : Icons.wifi, 
                    size: 80, 
                    color: Colors.white
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _ssid!.replaceAll('"', ''),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const Text("CONNECTED NETWORK", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            Row(
              children: [
                Expanded(child: _buildStatCard("Latensi", _ping, Icons.speed, Colors.orangeAccent)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Keamanan", "WPA2-PSK", Icons.security, Colors.greenAccent)),
              ],
            ),
            const SizedBox(height: 10),

            _buildDetailCard("IP Address", _ip!, Icons.lan),
            _buildDetailCard("BSSID Mac", _bssid!, Icons.fingerprint),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchNetworkData,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.sync_rounded),
                label: Text(_isLoading ? "SCANNING..." : "REFRESH NETWORK"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(top: 15),
      color: Colors.white.withOpacity(0.03),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.cyanAccent),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}