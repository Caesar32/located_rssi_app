import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(FlutterWifiIoT());

class FlutterWifiIoT extends StatefulWidget {
  @override
  _FlutterWifiIoTState createState() => _FlutterWifiIoTState();
}

class _FlutterWifiIoTState extends State<FlutterWifiIoT> {
  List<WifiNetwork?> _networks = [null, null, null];
  bool _isIndoor = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadWifiNetworks();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _loadWifiNetworks();
    });
  }

  Future<void> _loadWifiNetworks() async {
    setState(() {
      _isLoading = true;
    });

    List<WifiNetwork> networks;
    try {
      networks = await WiFiForIoTPlugin.loadWifiList();
    } catch (e) {
      print("Failed to load WiFi networks: $e");
      networks = [];
    }

    Map<String, WifiNetwork> networkMap = {};
    for (var network in networks) {
      if (network.ssid == "Redemi_Not_8" ||
          network.ssid == "BCD@Y9" ||
          network.ssid == "ESP32-third_node") {
        networkMap[network.ssid!] = network; // Use non-null assertion
      }
    }

    setState(() {
      _networks = [
        networkMap["Redemi_Not_8"],
        networkMap["BCD@Y9"],
        networkMap["ESP32-third_node"]
      ];
      _isIndoor = _isNetworkIndoor(networkMap["Redemi_Not_8"], 5) &&
          _isNetworkIndoor(networkMap["BCD@Y9"], 5) &&
          _isNetworkIndoor(networkMap["ESP32-third_node"], 4);
      _isLoading = false;
    });
  }

  bool _isNetworkIndoor(WifiNetwork? network, double threshold) {
    if (network == null) return false;
    final distance = _calculateDistance(network.level!.toInt());
    return distance < threshold;
  }

  num _calculateDistance(int rssi) {
    const double lambda = 0.125; // Wavelength in meters
    return (lambda * pow(10, rssi / -20)) / (4 * pi);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Networks',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WiFi Networks'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadWifiNetworks,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _networks.length,
                      itemBuilder: (context, index) {
                        final network = _networks[index];
                        if (network == null) {
                          return Card(
                            child: ListTile(
                              title: Text('Network not found'),
                              subtitle: Text(
                                _getNetworkName(index),
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        } else {
                          final distance =
                              _calculateDistance(network.level!.toInt());
                          return Card(
                            child: Column(
                              children: [
                                Text(network.ssid.toString()),
                                SizedBox(height: 5),
                                Text('RSSI: ${network.level} dBm'),
                                SizedBox(height: 5),
                                Text(
                                  'Distance: ${distance.toStringAsFixed(2)} meters',
                                  style: TextStyle(
                                    color: distance < 2
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _isIndoor ? 'Indoor' : 'Outdoor',
                    style: TextStyle(
                      color: _isIndoor ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getNetworkName(int index) {
    switch (index) {
      case 0:
        return "Redemi_Not_8";
      case 1:
        return "BCD@Y9";
      case 2:
        return "ESP32-third_node";
      default:
        return "";
    }
  }
}
