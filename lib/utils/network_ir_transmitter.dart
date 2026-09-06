import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:irblaster_controller/state/network_bridge_prefs.dart';
import 'package:irblaster_controller/utils/network_tcp.dart';

class NetworkIrTransmitter {
  NetworkIrTransmitter._();

  static const Duration _timeout = Duration(seconds: 5);

  static Future<void> send(int frequencyHz, List<int> pattern) async {
    final prefs = NetworkBridgePrefs.instance;
    if (prefs.host.isEmpty) {
      throw StateError(
        'Nenhum endereço do ESP32 configurado. Defina o IP/hostname em '
        'Configurações > Ponte de Rede.',
      );
    }

    final payload = jsonEncode({'freq': frequencyHz, 'pattern': pattern});
    if (prefs.wifiProtocol == WifiBridgeProtocol.tcpRealtime) {
      await sendTcp(prefs.host, prefs.tcpPort, payload);
      return;
    }
    await _sendHttp(prefs.host, payload);
  }

  static Future<void> _sendHttp(String host, String payload) async {
    final response = await http
        .post(
          Uri.parse('http://$host/api/send'),
          headers: const {'Content-Type': 'application/json'},
          body: payload,
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('ESP32 respondeu ${response.statusCode}: ${response.body}');
    }
  }

  static Future<bool> ping() async {
    final prefs = NetworkBridgePrefs.instance;
    if (prefs.host.isEmpty) return false;
    try {
      if (prefs.wifiProtocol == WifiBridgeProtocol.tcpRealtime) {
        return await pingTcp(prefs.host, prefs.tcpPort);
      } else {
        final response = await http
            .get(Uri.parse('http://${prefs.host}/api/status'))
            .timeout(_timeout);
        if (response.statusCode != 200) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
