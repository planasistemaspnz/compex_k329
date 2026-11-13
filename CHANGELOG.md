## 0.1.1

- Adicionado app de exemplo completo em `example/` demonstrando o uso de todos os widgets e
  serviços do pacote.
- README expandido com exemplo de uso, link para o app de exemplo e nota de troubleshooting
  para o bug de compilação incremental Kotlin em projetos Windows multi-drive.

## 0.1.0

- Primeira versão pública.
- Conexão Bluetooth clássica (RFCOMM) com a impressora, incluindo múltiplos fallbacks de socket
  e confirmação física de ACK após o envio.
- Geração de payload CPCL (monocromatização, conversão hexadecimal, comandos de página/impressão).
- Renderização da etiqueta (descrição, código de barras EAN-13/Code 128, preço, preço fracionado,
  data) para preview e impressão.
- Widgets reutilizáveis: `BluetoothStatusCard`, `DevicePickerBottomSheet`,
  `RotationSelectorWidget`, `SamplePresetsBar`, `LabelPreviewWidget`.
- Suporte nativo apenas Android; iOS retorna erro explícito de plataforma não suportada.
