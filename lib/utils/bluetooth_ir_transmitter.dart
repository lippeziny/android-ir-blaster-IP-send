import 'dart:async';
import 'dart:convert';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:irblaster_controller/state/network_bridge_prefs.dart';

class BluetoothIrDevice {
  final String address;
  final String name;
  final int? rssi;

  const BluetoothIrDevice({
    required this.address,
    required this.name,
    this.rssi,
  });
}

class BluetoothIrTransmitter {
  BluetoothIrTransmitter._();

  static final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  static dynamic _connection;
  static String _connectedAddress = '';

  static Future<List<BluetoothIrDevice>> scan() async {
    final devices = await _bluetooth.scan(timeout: const Duration(seconds: 8));
    return devices
        .map(
          (device) => BluetoothIrDevice(
            address: device.address.toString(),
            name: device.displayName.toString().trim().isEmpty
                ? 'ESP32'
                : device.displayName.toString(),
            rssi: device.rssi,
          ),
        )
        .toList(growable: false);
  }

  static Future<List<BluetoothIrDevice>> pairedDevices() async {
    final devices = await _bluetooth.getPairedDevices();
    return devices
        .map(
          (device) => BluetoothIrDevice(
            address: device.address.toString(),
            name: device.displayName.toString().trim().isEmpty
                ? 'ESP32'
                : device.displayName.toString(),
            rssi: device.rssi,
          ),
        )
        .toList(growable: false);
  }

  static Future<void> send(int frequencyHz, List<int> pattern) async {
    final prefs = NetworkBridgePrefs.instance;
    if (prefs.bluetoothAddress.isEmpty) {
      throw StateError(
        'Nenhum dispositivo Bluetooth selecionado. Escolha o ESP32 em '
        'Configurações > Ponte de Rede.',
      );
    }

    final connection = await _ensureConnection(prefs.bluetoothAddress);
    final payload = jsonEncode({'freq': frequencyHz, 'pattern': pattern});

    if (prefs.bluetoothProtocol == BluetoothBridgeProtocol.realtime) {
      await connection.output.writeLine(payload);
      return;
    }

    final reply = await connection.sendAndReceive(
      payload,
      timeout: const Duration(seconds: 5),
    );
    if (!reply.toString().contains('"ok":true')) {
      throw Exception('ESP32 respondeu via Bluetooth: $reply');
    }
  }

  static Future<dynamic> _ensureConnection(String address) async {
    if (_connection != null && _connectedAddress == address) {
      return _connection;
    }
    await disconnect();
    _connection = await _bluetooth.connect(
      address: address,
      uuid: BtcUuid.spp,
      timeout: const Duration(seconds: 8),
    );
    _connectedAddress = address;
    return _connection;
  }

  static Future<bool> ping() async {
    try {
      final prefs = NetworkBridgePrefs.instance;
      if (prefs.bluetoothAddress.isEmpty) return false;
      await _ensureConnection(prefs.bluetoothAddress);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    final current = _connection;
    _connection = null;
    _connectedAddress = '';
    if (current != null) {
      try {
        await current.finish();
      } catch (_) {
        try {
          await current.close();
        } catch (_) {}
      }
    }
  }
}
