import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GondolaLabelExampleApp());
    await tester.pump();

    expect(find.text('Exemplo compex_k329'), findsOneWidget);
    expect(find.text('IMPRIMIR ETIQUETA K329'), findsOneWidget);
  });
}
