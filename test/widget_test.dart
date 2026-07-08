import 'package:flutter_test/flutter_test.dart';
import 'package:gokyuzu_weather/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GokyuzuApp());

    // Verify that the title text containing 'Gök' is rendered
    expect(find.textContaining('Gök'), findsWidgets);
  });
}
