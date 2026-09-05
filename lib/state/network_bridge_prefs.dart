import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How (if at all) outgoing IR commands should be routed to an ESP32
/// bridge instead of the phone's own transmitter.
///
/// This is intentionally kept separate from [IrTransmitterType]
/// (`lib/utils/ir_transmitter_platform.dart`): that enum models the
/// *native* Android transmitters (internal emitter, USB dongle, audio
/// adapter) and is driven by Kotlin code behind a platform channel. The
/// network bridge below is a pure-Dart transport that, when enabled,
/// intercepts outgoing commands in `lib/utils/ir.dart` *before* they ever
/// reach that platform channel — so none of the native transmitter code
/// has to change for this feature to work.
enum NetworkBridgeMode { off, wifi, bluetooth }

extension NetworkBridgeModeX on NetworkBridgeMode {
  String get storageValue => name;

  static NetworkBridgeMode fromStorage(String? value) {
    switch (value) {
      case 'wifi':
        return NetworkBridgeMode.wifi;
      case 'bluetooth':
        return NetworkBridgeMode.bluetooth;
      case 'off':
      default:
        return NetworkBridgeMode.off;
    }
  }
}

/// Holds the user's ESP32 IR-bridge settings: whether it's enabled, and
/// which transport (Wi-Fi/HTTP for now; Bluetooth reserved for later) plus
/// connection details, persisted the same way as [TransmitterPrefs].
class NetworkBridgePrefs extends ChangeNotifier {
  NetworkBridgePrefs._();
  static final NetworkBridgePrefs instance = NetworkBridgePrefs._();

  static const String _kModeKey = 'network_bridge_mode_v1';
  static const String _kHostKey = 'network_bridge_host_v1';

  NetworkBridgeMode _mode = NetworkBridgeMode.off;
  String _host = '';

  NetworkBridgeMode get mode => _mode;
  bool get isEnabled => _mode != NetworkBridgeMode.off;
  bool get isWifi => _mode == NetworkBridgeMode.wifi;
  bool get isBluetooth => _mode == NetworkBridgeMode.bluetooth;

  /// IP address or hostname of the ESP32 (e.g. "192.168.4.1" or
  /// "irblaster.local"), without scheme or path.
  String get host => _host;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = NetworkBridgeModeX.fromStorage(prefs.getString(_kModeKey));
      _host = prefs.getString(_kHostKey) ?? '';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setMode(NetworkBridgeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kModeKey, mode.storageValue);
    } catch (_) {}
  }

  Future<void> setHost(String host) async {
    final trimmed = host.trim();
    if (_host == trimmed) return;
    _host = trimmed;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHostKey, trimmed);
    } catch (_) {}
  }
}
