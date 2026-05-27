import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:math';

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
        colorSchemeSeed: Colors.cyan,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// Navigasi Utama menggunakan BottomNavigationBar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const WifiHomeScreen(),
    const SpeedTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF0F132A),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white30,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analyzer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_outlined),
            activeIcon: Icon(Icons.speed),
            label: 'Speedtest',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN UTAMA: WIFI ANALYZER
// ==========================================
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
  int _signalStrength = -100;
  String _frequency = "N/A";
  String _distance = "N/A";
  bool _isPermissionGranted = false;

  final List<FlSpot> _signalHistory = [];
  int _timerCounter = 0;

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
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses[Permission.location]?.isGranted == true) {
      setState(() {
        _isPermissionGranted = true;
      });
      _fetchNetworkData();
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchNetworkData());
    } else {
      setState(() {
        _isPermissionGranted = false;
        _ssid = "Butuh Izin Lokasi";
      });
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Izin Diperlukan"),
        content: const Text("Aplikasi ini membutuhkan izin Lokasi dan Perangkat Sekitar untuk membaca data Wi-Fi secara akurat."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initApp();
            },
            child: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }

  String _calculateDistance(int rssi, int freq) {
    if (rssi == 0 || freq == 0) return "N/A";
    double exp = (27.55 - (20 * log(freq) / ln10) + rssi.abs()) / 20.0;
    return "${pow(10.0, exp).toStringAsFixed(1)} m";
  }

  Future<void> _fetchNetworkData() async {
    try {
      final ssid = await info.getWifiName();
      final ip = await info.getWifiIP();
      final bssid = await info.getWifiBSSID();
      int rssi = -100;
      int freq = 0;

      if (Platform.isAndroid) {
        rssi = await WiFiForIoTPlugin.getCurrentSignalStrength() ?? -100;
        freq = await WiFiForIoTPlugin.getFrequency() ?? 0;
      }

      String pingVal = "Offline";
      try {
        final sw = Stopwatch()..start();
        final res = await InternetAddress.lookup('8.8.8.8').timeout(const Duration(seconds: 1));
        if (res.isNotEmpty) {
          sw.stop();
          pingVal = "${sw.elapsedMilliseconds} ms";
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        if (ssid == "<unknown ssid>") {
          _ssid = "Aktifkan GPS HP";
        } else {
          _ssid = (ssid ?? "Tidak Terhubung").replaceAll('"', '');
        }
        
        _ip = ip ?? "0.0.0.0";
        _bssid = bssid ?? "Tidak Terdeteksi";
        _signalStrength = rssi;
        _frequency = freq > 0 ? "${(freq / 1000).toStringAsFixed(1)} GHz" : "N/A";
        _distance = _calculateDistance(rssi, freq);
        _ping = pingVal;

        _timerCounter++;
        _signalHistory.add(FlSpot(_timerCounter.toDouble(), rssi.toDouble()));
        
        if (_signalHistory.length > 10) {
          _signalHistory.removeAt(0);
        }
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _ssid != "Tidak Terhubung" && _ssid != "Memindai..." && _ssid != "Butuh Izin Lokasi" && _ssid != "Aktifkan GPS HP";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("WIFI ANALYZER PRO", 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNetworkData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeaderCard(isConnected),
              const SizedBox(height: 20),
              
              if (isConnected) _buildChartCard(),
              if (isConnected) const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildStatBox("Ping", _ping, Icons.bolt, Colors.orangeAccent)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatBox("Signal", "$_signalStrength dBm", Icons.wifi_tethering, _getSignalColor())),
                ],
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(child: _buildStatBox("Freq", _frequency, Icons.radar, Colors.purpleAccent)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatBox("Est. Distance", _distance, Icons.straighten, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 25),
    
              _buildDetailTile("IP Address", _ip, Icons.lan_outlined),
              _buildDetailTile("MAC / BSSID", _bssid, Icons.fingerprint),
              _buildDetailTile("Gateway", _ip != "0.0.0.0" ? "${_ip.substring(0, _ip.lastIndexOf('.'))}.1" : "N/A", Icons.router_outlined),
              
              const SizedBox(height: 20),
              
              if (!_isPermissionGranted)
                ElevatedButton.icon(
                  onPressed: _initApp,
                  icon: const Icon(Icons.security),
                  label: const Text("Berikan Izin Manual"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade800, foregroundColor: Colors.white),
                ),
                
              const SizedBox(height: 10),
              const Text("DATA UPDATED EVERY 2 SECONDS", 
                style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Signal Stability (dBm)", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: _signalHistory.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: _leftTitleWidgets,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: -100,
                      maxY: -30,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _signalHistory,
                          isCurved: true,
                          color: Colors.cyanAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.cyan.withOpacity(0.1),
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

  static Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == -30 || value == -60 || value == -90) {
      return Text(
        value.toInt().toString(),
        style: const TextStyle(color: Colors.white30, fontSize: 10),
      );
    }
    return Container();
  }

  Widget _buildHeaderCard(bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected 
            ? [Colors.cyan.shade700, Colors.blue.shade900] 
            : [Colors.grey.shade900, Colors.black],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Icon(isConnected ? Icons.wifi : Icons.wifi_off, size: 60, color: Colors.white),
          const SizedBox(height: 15),
          Text(_ssid, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(isConnected ? "KONEKSI STABIL" : "PERIKSA PERANGKAT", 
            style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getSignalColor() {
    if (_signalStrength >= -60) return Colors.greenAccent;
    if (_signalStrength >= -80) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

// ==========================================
// HALAMAN: FITUR SPEEDTEST (FIXED SERVER VERSION)
// ==========================================
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  bool _isTesting = false;
  double _speedMbps = 0.0;
  double _progress = 0.0;
  String _statusText = "Siap Menguji";

  // PERBAIKAN UTAMA: Menggunakan cermin peladen Hetzner Jerman (sangat stabil untuk download chunk)
  final String _testUrl = "https://speed.hetzner.de/10MB.bin";

  Future<void> _startSpeedTest() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _speedMbps = 0.0;
      _progress = 0.0;
      _statusText = "Menghubungkan ke server...";
    });

    try {
      final stopwatch = Stopwatch()..start();
      final client = http.Client();
      
      final request = http.Request('GET', Uri.parse(_testUrl));
      final response = await client.send(request).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        int contentLength = response.contentLength ?? 10485760; // 10MB Fallback
        int bytesReceived = 0;

        setState(() {
          _statusText = "Mengunduh data uji...";
        });

        await for (List<int> chunk in response.stream) {
          bytesReceived += chunk.length;
          
          double currentProgress = bytesReceived / contentLength;
          double elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
          double currentSpeedMbps = 0.0;
          
          if (elapsedSeconds > 0) {
            currentSpeedMbps = (bytesReceived * 8) / (1024 * 1024) / elapsedSeconds;
          }

          if (mounted) {
            setState(() {
              _progress = currentProgress > 1.0 ? 1.0 : currentProgress;
              _speedMbps = currentSpeedMbps;
            });
          }
        }
        stopwatch.stop();
        
        setState(() {
          _isTesting = false;
          _statusText = "Pengujian Selesai!";
        });
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _statusText = "Gagal menguji. Periksa internet Anda.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("INTERNET SPEEDTEST", 
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _isTesting ? _progress : (_speedMbps > 0 ? 1.0 : 0.0),
                      strokeWidth: 12,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _speedMbps > 50 ? Colors.greenAccent : (_speedMbps > 20 ? Colors.cyanAccent : Colors.orangeAccent)
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _speedMbps.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        "Mbps",
                        style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 10),
              if (_isTesting)
                Text(
                  "${(_progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
                
              const SizedBox(height: 50),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _startSpeedTest,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _isTesting ? "MENGUJI..." : "MULAI SPEEDTEST",
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}