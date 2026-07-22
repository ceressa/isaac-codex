import 'package:flutter_test/flutter_test.dart';

import 'package:boi_wiki/main.dart';

void main() {
  testWidgets('App boots and shows search bar', (WidgetTester tester) async {
    await tester.pumpWidget(const BoiWikiApp());
    expect(find.text('Isaac Wiki'), findsOneWidget);
  });
}
