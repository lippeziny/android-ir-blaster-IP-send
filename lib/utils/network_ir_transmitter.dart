import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:irblaster_controller/state/network_bridge_prefs.dart';

/// Sends IR commands to an ESP32 IR bridge over the local network instead
/// of the phone's native IR transmitter. Talks to the firmware's
/// `POST /api/send` endpoint using the exact same (frequency, pattern)
/// pair the app's protocol encoders already compute — see
/// `lib/utils/ir.dart` for where this is wired in.
///
/// Deliberately uses the `http` package that's already a dependency of
/// this project (no new pub packages added for the Wi-Fi transport).
class NetworkIrTransmitter {
  NetworkIrTransmitter._();

  static const Duration _timeout = Duration(seconds: 5);

  /// Throws a [StateError] if no host is configured, or an [Exception] if
  /// the request fails or the ESP32 reports an error.
  static Future<void> send(int frequencyHz, List<int> pattern) async {
    final host = NetworkBridgePrefs.instance.host;
    if (host.isEmpty) {
      throw StateError(
        'Nenhum endereço do ESP32 configurado. Defina o IP/hostname em '
        'Configurações > Ponte de Rede (ESP32).',
      );
    }

    final uri = Uri.parse('http://$host/api/send');
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'freq': frequencyHz, 'pattern': pattern}),
          )
          .timeout(_timeout);
    } catch (e) {
      throw Exception('Não foi possível falar com o ESP32 ($host): $e');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'ESP32 respondeu ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Quick reachability check for the settings screen ("Testar conexão")
  /// — hits `/api/status` instead of actually firing IR.
  static Future<bool> ping() async {
    final host = NetworkBridgePrefs.instance.host;
    if (host.isEmpty) return false;
    try {
      final uri = Uri.parse('http://$host/api/status');
      final response = await http.get(uri).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
