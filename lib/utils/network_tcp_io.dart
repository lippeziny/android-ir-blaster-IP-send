import 'dart:io';

Future<void> sendTcp(String host, int port, String payload) async {
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    socket.write('$payload\n');
    await socket.flush();
  } finally {
    await socket?.close();
  }
}

Future<bool> pingTcp(String host, int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    return true;
  } catch (_) {
    return false;
  } finally {
    await socket?.close();
  }
}
