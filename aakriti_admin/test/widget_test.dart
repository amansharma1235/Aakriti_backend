import 'package:flutter_test/flutter_test.dart';
import 'package:aakriti_admin/main.dart';

void main() {
  testWidgets('Aakriti Admin app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AakritiAdminApp());

    expect(find.text('Admin Login'), findsOneWidget);
  });
}
