import 'package:flutter/material.dart';
import 'package:irblaster_controller/state/network_bridge_prefs.dart';
import 'package:irblaster_controller/utils/network_ir_transmitter.dart';

/// Settings card for the ESP32 IR bridge: lets the user route outgoing IR
/// commands over Wi-Fi (HTTP) to an ESP32 instead of using the phone's own
/// IR hardware. Bluetooth is listed but disabled until that transport is
/// implemented (see `lib/utils/ir.dart`).
///
/// Mirrors the plain-ListTile-with-radio-icon style already used by
/// `_TransmitterOptionTile` in settings_screen.dart, rather than
/// `RadioListTile`, for visual consistency with the rest of the screen.
class NetworkBridgeCard extends StatefulWidget {
  const NetworkBridgeCard({super.key});

  @override
  State<NetworkBridgeCard> createState() => _NetworkBridgeCardState();
}

class _NetworkBridgeCardState extends State<NetworkBridgeCard> {
  late final TextEditingController _hostController;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _hostController =
        TextEditingController(text: NetworkBridgePrefs.instance.host);
    NetworkBridgePrefs.instance.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    NetworkBridgePrefs.instance.removeListener(_onPrefsChanged);
    _hostController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final ok = await NetworkIrTransmitter.ping();
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Conectado ao ESP32 com sucesso.'
              : 'Não foi possível conectar ao ESP32. Confira o IP e a rede.',
        ),
      ),
    );
  }

  Widget _modeTile({
    required NetworkBridgeMode value,
    required String title,
    required String subtitle,
    required IconData icon,
    bool enabled = true,
  }) {
    final prefs = NetworkBridgePrefs.instance;
    final selected = prefs.mode == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
      ),
      onTap: enabled ? () => prefs.setMode(value) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = NetworkBridgePrefs.instance;
    final cs = Theme.of(context).colorScheme;

    return Column(
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
          title: 'Wi-Fi (ESP32 na rede)',
          subtitle: 'Envia os comandos por HTTP para o IP do ESP32',
          icon: Icons.wifi_rounded,
        ),
        if (prefs.isWifi)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'IP ou hostname do ESP32',
                      hintText: 'ex: 192.168.4.1 ou irblaster.local',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (v) => prefs.setHost(v),
                    onEditingComplete: () => prefs.setHost(_hostController.text),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _testing
                      ? null
                      : () {
                          prefs.setHost(_hostController.text);
                          _testConnection();
                        },
                  child: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Testar'),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        _modeTile(
          value: NetworkBridgeMode.bluetooth,
          title: 'Bluetooth (em breve)',
          subtitle: 'Ainda não implementado nesta versão',
          icon: Icons.bluetooth_rounded,
          enabled: false,
        ),
        if (prefs.isEnabled) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
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
                    'Enquanto a Ponte de Rede estiver ativa, os botões dos '
                    'controles são enviados para o ESP32 em vez do '
                    'transmissor selecionado na seção acima.',
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
