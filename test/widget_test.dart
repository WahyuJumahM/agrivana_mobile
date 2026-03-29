import 'package:flutter_test/flutter_test.dart';
import 'package:agrivana/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgrivanaApp());
    // Verify the app at least renders
    expect(find.byType(AgrivanaApp), findsOneWidget);
  });
}
