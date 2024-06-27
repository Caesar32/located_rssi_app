import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:async';

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
      if (network.ssid == "ESP32-first_node" ||
          network.ssid == "ESP32-second_node") {
        networkMap[network.ssid!] = network; // Use non-null assertion
      }
    }

    setState(() {
      _networks = [
        networkMap["ESP32-first_node"],
        networkMap["ESP32-second_node"],
      ];
      _isIndoor = _isNetworkIndoor(networkMap["ESP32-first_node"], -85) &&
          _isNetworkIndoor(networkMap["ESP32-second_node"], -62);
      _isLoading = false;
    });
  }

  bool _isNetworkIndoor(WifiNetwork? network, int threshold) {
    if (network == null) return false;
    return network.level! >= threshold;
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
                          return Card(
                            child: Column(
                              children: [
                                Text(network.ssid.toString()),
                                SizedBox(height: 5),
                                Text('RSSI: ${network.level} dBm',
                                    style: TextStyle(
                                      color: network.level! > -70
                                          ? Colors.green
                                          : Colors.red,
                                    )),
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
        return "ESP32-first_node";
      case 1:
        return "ESP32-second_node";
      default:
        return "";
    }
  }
}
