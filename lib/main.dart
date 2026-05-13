import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart'; 
import 'dart:async';
import 'dart:io';

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
  Timer? _timer;
  
  String _ssid = "Memindai...";
  String _ip = "0.0.0.0";
  String _bssid = "00:00:00:00:00";
  String _ping = "N/A";
  int _signalStrength = 0;
  String _frequency = "N/A";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    // Meminta izin lokasi (Wajib untuk WiFi di Android)
    await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
    
    _fetchNetworkData();
    // Refresh otomatis tiap 3 detik
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchNetworkData());
  }

  Future<void> _fetchNetworkData() async {
    try {
      final ssid = await info.getWifiName();
      final ip = await info.getWifiIP();
      final bssid = await info.getWifiBSSID();

      int rssi = 0;
      int freq = 0;

      // Hanya jalankan wifi_iot di Android fisik
      if (Platform.isAndroid) {
        rssi = await WiFiForIoTPlugin.getCurrentSignalStrength() ?? 0;
        freq = await WiFiForIoTPlugin.getFrequency() ?? 0;
      }

      String pingResult = "Timeout";
      try {
        final stopwatch = Stopwatch()..start();
        final result = await InternetAddress.lookup('8.8.8.8')
            .timeout(const Duration(seconds: 1));
        if (result.isNotEmpty) {
          stopwatch.stop();
          pingResult = "${stopwatch.elapsedMilliseconds} ms";
        }
      } catch (_) {
        pingResult = "Offline";
      }

      if (!mounted) return;

      setState(() {
        _ssid = (ssid ?? "Tidak Terhubung").replaceAll('"', '');
        _ip = ip ?? "0.0.0.0";
        _bssid = bssid ?? "Unknown BSSID";
        _ping = pingResult;
        _signalStrength = rssi;
        _frequency = freq > 0 ? "${(freq / 1000).toStringAsFixed(1)} GHz" : "N/A";
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _ssid != "Tidak Terhubung" && _ssid != "Memindai...";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("WIFI ANALYZER PRO", 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMainCard(isConnected),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildStatBox("Ping", _ping, Icons.speed, Colors.orange)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatBox("Signal", "$_signalStrength dBm", Icons.signal_wifi_4_bar, Colors.green)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildStatBox("Freq", _frequency, Icons.radar, Colors.purpleAccent)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatBox("Security", "WPA2/3", Icons.lock, Colors.blue)),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailTile("IP Address", _ip, Icons.dns),
            _buildDetailTile("MAC Address", _bssid, Icons.fingerprint),
            const SizedBox(height: 30),
            const Text("Live Monitoring Active", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected ? [Colors.cyan, Colors.blueAccent] : [Colors.grey.shade800, Colors.black],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Icon(isConnected ? Icons.wifi : Icons.wifi_off, size: 60, color: Colors.white),
          const SizedBox(height: 15),
          Text(_ssid, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(isConnected ? "CONNECTED" : "DISCONNECTED", style: const TextStyle(fontSize: 10, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}