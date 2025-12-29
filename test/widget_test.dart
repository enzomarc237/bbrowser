import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:bbrowser/main.dart';

void main() {
  testWidgets('Main UI layout test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app has a MacosWindow and MacosScaffold.
    expect(find.byType(MacosWindow), findsOneWidget);
    expect(find.byType(MacosScaffold), findsOneWidget);
  });
}