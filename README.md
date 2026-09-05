# Patch: Ponte de Rede (ESP32) para o IR Blaster

Isso complementa o firmware em `esp32-ir-bridge/` (mensagem anterior).
Aqui está a parte do app Flutter: uma nova opção "Wi-Fi (ESP32 na rede)"
nas configurações, que manda os comandos IR por HTTP para o ESP32 em vez
de usar o transmissor nativo do celular.

## O que foi mudado e por quê

**Nada no código nativo Android/Kotlin foi tocado.** A ideia foi
interceptar o envio já na camada Dart, exatamente no ponto em que o app
calcula `(frequência, padrão)` e — hoje — manda isso direto pro canal
nativo. Isso significa: menos superfície de coisa pra quebrar na hora de
compilar, que era o seu problema até agora.

**Arquivos novos** (em `lib/`, é só criar esses caminhos no seu fork):
- `state/network_bridge_prefs.dart` — guarda o modo (desativado/Wi-Fi/
  Bluetooth) e o IP/host do ESP32, salvo com `shared_preferences` (mesmo
  pacote que o projeto já usa).
- `utils/network_ir_transmitter.dart` — manda o POST HTTP pro ESP32,
  usando o pacote `http` que **já é dependência do projeto** (nenhuma
  dependência nova foi adicionada).
- `widgets/settings/widgets/network_bridge_card.dart` — o card novo na
  tela de Configurações.

**Arquivos existentes editados** (4 arquivos, mudança pequena em cada —
os diffs completos estão em `diffs/`, mas o mais fácil no celular é
simplesmente **substituir o arquivo inteiro** pelo que está aqui em
`lib/`):
- `lib/main.dart` — carrega as novas preferências ao iniciar o app.
- `lib/utils/ir.dart` — `transmit()`/`transmitRaw()` agora checam se a
  Ponte de Rede está ativa antes de chamar o canal nativo.
- `lib/widgets/remote_view.dart` — não mostra mais o aviso de "sem
  emissor de IR" quando a Ponte de Rede está ativa.
- `lib/widgets/settings_screen.dart` — adiciona a seção "Ponte de Rede
  (ESP32)" logo abaixo da seção de transmissor.

## Como aplicar no seu fork

Pelo celular, o caminho mais simples é abrir cada arquivo acima no editor
web do GitHub (tecla `.` no repo abre o editor, ou o app do GitHub) e:
- Para os 3 arquivos novos: criar o arquivo no caminho indicado e colar
  o conteúdo.
- Para os 4 arquivos editados: abrir o arquivo, selecionar tudo, colar o
  conteúdo do arquivo correspondente aqui em `lib/`.

Depois, em Configurações > **Ponte de Rede (ESP32)**, escolha "Wi-Fi" e
digite o IP do ESP32 (ex: `192.168.4.1` se estiver no modo AP direto do
firmware, ou o IP que ele pegar da sua rede de casa). Toque em "Testar"
para confirmar a conexão.

## Sobre o erro de compilação recorrente no GitHub Actions

Dei uma olhada no repositório e acho que achei a causa raiz (incluí um
workflow corrigido em `.github/workflows/build-apk.yml`):

1. **O projeto usa o próprio Flutter, fixado como git submodule** (pasta
   `.flutter`, veja `.gitmodules`). Se o checkout do Actions não trouxer
   os submodules e o workflow instalar "qualquer" Flutter estável por
   fora, você compila com uma versão diferente da que o projeto espera —
   isso bate exatamente com o tipo de erro de dependência que você
   descreveu.
2. O projeto usa **Android Gradle Plugin 8.13.1** com `compileSdk 36`,
   que precisa de um **JDK 17 ou 21** para rodar o Gradle (mesmo o app
   compilando para Java 11).

O workflow novo resolve os dois pontos. Se ainda assim der erro, me
manda o log — com um erro real na mão eu conserto de vez.

## Limitações desta primeira versão

- **Bluetooth**: a opção aparece na tela mas ainda não está implementada
  (falta escolher um pacote Flutter de Bluetooth Classic/SPP e integrar).
  Posso fazer isso numa próxima etapa.
- **Modo "Universal Power"** (a função que testa vários códigos de
  liga/desliga em sequência) continua usando o transmissor nativo do
  celular mesmo com a Ponte de Rede ativada — ela dispara muitos sinais
  por segundo e o protocolo atual do ESP32 não foi pensado pra esse caso.
- Sinais "aprendidos" via dongle USB em formato proprietário (Tiqiaa/
  Huawei/LG) que não têm um padrão raw de fallback não podem ser
  reproduzidos pelo ESP32 — só os que já têm prévia em raw funcionam
  (a maioria).
