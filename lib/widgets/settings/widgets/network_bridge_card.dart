import 'package:flutter/material.dart';
import 'package:irblaster_controller/state/network_bridge_prefs.dart';
import 'package:irblaster_controller/utils/bluetooth_ir_transmitter.dart';
import 'package:irblaster_controller/utils/network_ir_transmitter.dart';

class NetworkBridgeCard extends StatefulWidget {
  const NetworkBridgeCard({super.key});

  @override
  State<NetworkBridgeCard> createState() => _NetworkBridgeCardState();
}

class _NetworkBridgeCardState extends State<NetworkBridgeCard> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  bool _testing = false;
  bool _scanning = false;
  List<BluetoothIrDevice> _devices = const [];

  @override
  void initState() {
    super.initState();
    final prefs = NetworkBridgePrefs.instance;
    _hostController = TextEditingController(text: prefs.host);
    _portController = TextEditingController(text: prefs.tcpPort.toString());
    prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    NetworkBridgePrefs.instance.removeListener(_onPrefsChanged);
    _hostController.dispose();
    _portController.dispose();
    BluetoothIrTransmitter.disconnect();
    super.dispose();
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    final prefs = NetworkBridgePrefs.instance;
    if (_hostController.text != prefs.host) _hostController.text = prefs.host;
    if (_portController.text != prefs.tcpPort.toString()) {
      _portController.text = prefs.tcpPort.toString();
    }
    setState(() {});
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final prefs = NetworkBridgePrefs.instance;
    final ok = prefs.isWifi
        ? await NetworkIrTransmitter.ping()
        : await BluetoothIrTransmitter.ping();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Conexão com o ESP32 confirmada.'
              : 'Não foi possível conectar. Confira a rede, o endereço e o pareamento.',
        ),
      ),
    );
  }

  Future<void> _scanBluetooth() async {
    setState(() => _scanning = true);
    try {
      final paired = await BluetoothIrTransmitter.pairedDevices();
      final discovered = await BluetoothIrTransmitter.scan();
      final byAddress = <String, BluetoothIrDevice>{
        for (final item in [...paired, ...discovered]) item.address: item,
      };
      if (!mounted) return;
      setState(() {
        _devices = byAddress.values.toList(growable: false);
        _scanning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bluetooth indisponível: $error')),
      );
    }
  }

  Widget _modeTile({
    required NetworkBridgeMode value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final prefs = NetworkBridgePrefs.instance;
    return RadioListTile<NetworkBridgeMode>(
      value: value,
      groupValue: prefs.mode,
      onChanged: (next) {
        if (next != null) prefs.setMode(next);
      },
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _protocolDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = NetworkBridgePrefs.instance;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _modeTile(
          value: NetworkBridgeMode.off,
          title: 'Desativado',
          subtitle: 'Usar o transmissor do celular selecionado acima',
          icon: Icons.phone_iphone_rounded,
        ),
        const Divider(height: 1),
        _modeTile(
          value: NetworkBridgeMode.wifi,
          title: 'Wi‑Fi — ESP32 na rede',
          subtitle: 'Funciona pela rede local usando HTTP ou TCP',
          icon: Icons.wifi_rounded,
        ),
        if (prefs.isWifi) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'IP ou hostname do ESP32',
              hintText: '192.168.4.1 ou irblaster.local',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            onSubmitted: prefs.setHost,
            onEditingComplete: () => prefs.setHost(_hostController.text),
          ),
          const SizedBox(height: 10),
          _protocolDropdown<WifiBridgeProtocol>(
            label: 'Protocolo Wi‑Fi',
            value: prefs.wifiProtocol,
            items: const [
              DropdownMenuItem(
                value: WifiBridgeProtocol.http,
                child: Text('HTTP — confirmado pelo ESP32'),
              ),
              DropdownMenuItem(
                value: WifiBridgeProtocol.tcpRealtime,
                child: Text('TCP — tempo real, sem esperar resposta'),
              ),
            ],
            onChanged: (value) {
              if (value != null) prefs.setWifiProtocol(value);
            },
          ),
          if (prefs.wifiProtocol == WifiBridgeProtocol.tcpRealtime) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Porta TCP',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) => prefs.setTcpPort(int.tryParse(value) ?? 3333),
            ),
          ],
        ],
        const Divider(height: 1),
        _modeTile(
          value: NetworkBridgeMode.bluetooth,
          title: 'Bluetooth Classic — ESP32 pareado',
          subtitle: 'Comunicação SPP/RFCOMM com o ESP32 clássico',
          icon: Icons.bluetooth_rounded,
        ),
        if (prefs.isBluetooth) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  prefs.bluetoothName.isEmpty
                      ? 'Nenhum dispositivo selecionado'
                      : '${prefs.bluetoothName}\n${prefs.bluetoothAddress}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _scanning ? null : _scanBluetooth,
                icon: _scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text('Procurar'),
              ),
            ],
          ),
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._devices.map(
              (device) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bluetooth_connected_rounded),
                title: Text(device.name),
                subtitle: Text(device.address),
                trailing: device.address == prefs.bluetoothAddress
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () => prefs.setBluetoothDevice(
                  address: device.address,
                  name: device.name,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _protocolDropdown<BluetoothBridgeProtocol>(
            label: 'Protocolo Bluetooth',
            value: prefs.bluetoothProtocol,
            items: const [
              DropdownMenuItem(
                value: BluetoothBridgeProtocol.confirmed,
                child: Text('Padrão — espera confirmação'),
              ),
              DropdownMenuItem(
                value: BluetoothBridgeProtocol.realtime,
                child: Text('Tempo real — não espera resposta'),
              ),
            ],
            onChanged: (value) {
              if (value != null) prefs.setBluetoothProtocol(value);
            },
          ),
        ],
        if (prefs.isEnabled) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _testing ? null : _testConnection,
            icon: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded),
            label: const Text('Testar conexão'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enquanto a ponte estiver ativa, os botões dos controles '
                    'serão enviados ao ESP32. O protocolo pode ser trocado '
                    'a qualquer momento nesta tela.',
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
