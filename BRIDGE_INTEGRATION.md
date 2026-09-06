# Integração com ESP32 IR Bridge

O app agora possui três opções na seção **Configurações → Ponte de Rede (ESP32)**:

| Transporte | Opção | Comportamento |
|---|---|---|
| Desativado | Transmissor do celular | Mantém o funcionamento original do app |
| Wi‑Fi | HTTP | Envia para `POST /api/send` e aguarda confirmação |
| Wi‑Fi | TCP tempo real | Envia JSON terminado por `\n` para a porta TCP 3333 sem aguardar resposta |
| Bluetooth Classic | Padrão | Envia por SPP/RFCOMM e aguarda `{"ok":true}` |
| Bluetooth Classic | Tempo real | Envia por SPP/RFCOMM sem aguardar resposta |

## Configuração Wi‑Fi

Informe o IP ou hostname do ESP32. Para HTTP, use o endereço normalmente, por exemplo `192.168.4.1` ou `irblaster.local`. Para TCP, o firmware atualizado escuta a porta 3333 por padrão.

## Configuração Bluetooth

O Bluetooth do firmware é **Bluetooth Classic SPP**, não BLE. No app, entre em **Ponte de Rede → Bluetooth Classic**, toque em **Procurar**, selecione o ESP32 e escolha o protocolo. O Android pode solicitar permissões de dispositivos próximos e, em versões antigas, localização para a busca.

Bluetooth Classic está disponível no ESP32 clássico. ESP32-C3, C6 e S2 não possuem esse rádio e devem usar Wi‑Fi.

## Firmware

O firmware atualizado está na pasta `esp32-ir-bridge/` e contém somente `esp32-ir-bridge.ino` e `README.md`. O servidor TCP usa a porta 3333. O LED de status usa GPIO 2 por padrão, pisca quando não há conexão, apaga quando há conexão e faz um flash curto após uma transmissão.

Na Arduino IDE, selecione **Huge APP (3MB No OTA/1MB SPIFFS)** ou outra partição com pelo menos 2 MB de aplicativo.
