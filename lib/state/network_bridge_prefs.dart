import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NetworkBridgeMode { off, wifi, bluetooth }

enum WifiBridgeProtocol { http, tcpRealtime }

enum BluetoothBridgeProtocol { confirmed, realtime }

extension NetworkBridgeModeX on NetworkBridgeMode {
  String get storageValue => name;

  static NetworkBridgeMode fromStorage(String? value) {
    return NetworkBridgeMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => NetworkBridgeMode.off,
    );
  }
}

extension WifiBridgeProtocolX on WifiBridgeProtocol {
  String get storageValue => name;

  static WifiBridgeProtocol fromStorage(String? value) {
    return WifiBridgeProtocol.values.firstWhere(
      (item) => item.name == value,
      orElse: () => WifiBridgeProtocol.http,
    );
  }
}

extension BluetoothBridgeProtocolX on BluetoothBridgeProtocol {
  String get storageValue => name;

  static BluetoothBridgeProtocol fromStorage(String? value) {
    return BluetoothBridgeProtocol.values.firstWhere(
      (item) => item.name == value,
      orElse: () => BluetoothBridgeProtocol.confirmed,
    );
  }
}

class NetworkBridgePrefs extends ChangeNotifier {
  NetworkBridgePrefs._();
  static final NetworkBridgePrefs instance = NetworkBridgePrefs._();

  static const _modeKey = 'network_bridge_mode_v2';
  static const _legacyModeKey = 'network_bridge_mode_v1';
  static const _hostKey = 'network_bridge_host_v2';
  static const _legacyHostKey = 'network_bridge_host_v1';
  static const _wifiProtocolKey = 'network_bridge_wifi_protocol_v1';
  static const _bluetoothProtocolKey = 'network_bridge_bluetooth_protocol_v1';
  static const _bluetoothAddressKey = 'network_bridge_bluetooth_address_v1';
  static const _bluetoothNameKey = 'network_bridge_bluetooth_name_v1';
  static const _tcpPortKey = 'network_bridge_tcp_port_v1';

  NetworkBridgeMode _mode = NetworkBridgeMode.off;
  WifiBridgeProtocol _wifiProtocol = WifiBridgeProtocol.http;
  BluetoothBridgeProtocol _bluetoothProtocol = BluetoothBridgeProtocol.confirmed;
  String _host = '';
  String _bluetoothAddress = '';
  String _bluetoothName = '';
  int _tcpPort = 3333;

  NetworkBridgeMode get mode => _mode;
  WifiBridgeProtocol get wifiProtocol => _wifiProtocol;
  BluetoothBridgeProtocol get bluetoothProtocol => _bluetoothProtocol;
  String get host => _host;
  String get bluetoothAddress => _bluetoothAddress;
  String get bluetoothName => _bluetoothName;
  int get tcpPort => _tcpPort;
  bool get isEnabled => _mode != NetworkBridgeMode.off;
  bool get isWifi => _mode == NetworkBridgeMode.wifi;
  bool get isBluetooth => _mode == NetworkBridgeMode.bluetooth;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = NetworkBridgeModeX.fromStorage(
        prefs.getString(_modeKey) ?? prefs.getString(_legacyModeKey),
      );
      _wifiProtocol = WifiBridgeProtocolX.fromStorage(
        prefs.getString(_wifiProtocolKey),
      );
      _bluetoothProtocol = BluetoothBridgeProtocolX.fromStorage(
        prefs.getString(_bluetoothProtocolKey),
      );
      _host = prefs.getString(_hostKey) ?? prefs.getString(_legacyHostKey) ?? '';
      _bluetoothAddress = prefs.getString(_bluetoothAddressKey) ?? '';
      _bluetoothName = prefs.getString(_bluetoothNameKey) ?? '';
      _tcpPort = prefs.getInt(_tcpPortKey) ?? 3333;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setMode(NetworkBridgeMode value) async {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, value.storageValue);
  }

  Future<void> setWifiProtocol(WifiBridgeProtocol value) async {
    if (_wifiProtocol == value) return;
    _wifiProtocol = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wifiProtocolKey, value.storageValue);
  }

  Future<void> setBluetoothProtocol(BluetoothBridgeProtocol value) async {
    if (_bluetoothProtocol == value) return;
    _bluetoothProtocol = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bluetoothProtocolKey, value.storageValue);
  }

  Future<void> setHost(String value) async {
    final trimmed = value.trim();
    if (_host == trimmed) return;
    _host = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, trimmed);
  }

  Future<void> setBluetoothDevice({required String address, String name = ''}) async {
    _bluetoothAddress = address.trim();
    _bluetoothName = name.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bluetoothAddressKey, _bluetoothAddress);
    await prefs.setString(_bluetoothNameKey, _bluetoothName);
  }

  Future<void> setTcpPort(int value) async {
    if (value < 1 || value > 65535 || _tcpPort == value) return;
    _tcpPort = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tcpPortKey, value);
  }
}
