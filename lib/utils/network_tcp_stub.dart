Future<void> sendTcp(String host, int port, String payload) async {
  throw UnsupportedError('TCP tempo real não está disponível nesta plataforma.');
}

Future<bool> pingTcp(String host, int port) async => false;
