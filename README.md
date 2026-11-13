# compex_k329

Camada reutilizável para impressão de etiquetas de gôndola (preço de produto) via Bluetooth
clássico (RFCOMM/SPP) em impressoras térmicas compatíveis com o protocolo CPCL, como a **K329**.

Oferece:

- Gerenciamento de conexão Bluetooth clássica (pareamento, conexão com múltiplos fallbacks,
  transmissão com confirmação física de ACK da impressora).
- Geração do payload CPCL completo (monocromatização da imagem, conversão hexadecimal, montagem
  dos comandos `! / PAGE-WIDTH / EG / FORM / PRINT`).
- Renderização da etiqueta (descrição, código de barras EAN-13/Code 128, preço, preço fracionado,
  data) para preview e para impressão.
- Widgets prontos para compor uma tela de impressão: status da conexão Bluetooth, seletor de
  dispositivo pareado, seletor de rotação, barra de amostras rápidas e preview ao vivo da etiqueta.

## Suporte de plataforma

| Plataforma | Suporte |
|---|---|
| Android | Completo (Bluetooth clássico via socket RFCOMM nativo) |
| iOS | Não suportado — toda chamada retorna um erro claro (`PlatformException` código `UNSUPPORTED_PLATFORM`), nunca trava ou derruba o app |

## Uso básico

```dart
import 'package:compex_k329/models/gondola_label_model.dart';
import 'package:compex_k329/services/bluetooth_printer_service.dart';
import 'package:compex_k329/services/cpcl_service.dart';

final btService = BluetoothPrinterService();

// 1. Descobrir e conectar a uma impressora pareada
final devices = await btService.getDevices();

// 2. Montar o modelo da etiqueta
final model = GondolaLabelModel(
  description: 'AZEITE DE OLIVA EXTRA VIRGEM 500ML',
  price: '28,90',
  unit: 'UN',
  fractionalPrice: 'R\$ 57,80 por LITRO',
  barcode: '7896543215789',
);

// 3. Gerar o payload CPCL e imprimir
final payload = await CpclService.generatePrintPayload(model);
await btService.printLabelAtomic(devices.first, payload);
```

Os widgets em `package:compex_k329/widgets/` (`BluetoothStatusCard`,
`DevicePickerBottomSheet`, `RotationSelectorWidget`, `SamplePresetsBar`,
`LabelPreviewWidget`) são blocos de baixo nível para montar sua própria tela — este pacote
não impõe uma tela/formulário pronto.

## Exemplo completo

A pasta [`example/`](example) traz um app Flutter completo e funcional usando todos os blocos
acima: card de status Bluetooth, seletor de dispositivo pareado, seletor de rotação, preview
ao vivo da etiqueta, barra de amostras rápidas e o formulário de dados do produto. Rode com:

```
cd example
flutter run
```

## Permissões Android

O pacote já declara, via manifest merge automático do Gradle, as permissões necessárias
(`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`,
`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`). Nenhuma configuração adicional é
necessária no app host além de adicionar a dependência.

## Nota para desenvolvimento no Windows

Se o build Android (`flutter build apk` / `flutter run`) falhar com um erro do tipo
`this and base files have different roots` durante a compilação Kotlin de algum plugin
transitivo (ex.: `shared_preferences_android`), é um bug conhecido da compilação incremental
do Kotlin quando o projeto e o cache do pub/Gradle estão em drives diferentes (ex.: projeto em
`D:\` e cache em `C:\Users\...`). Contorne adicionando ao `android/gradle.properties` do app:

```properties
kotlin.incremental=false
```

## Licença

MIT — veja o arquivo [LICENSE](LICENSE).
