import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/app/app.dart';

void main() {
  testWidgets('ShopSphere app launches successfully', (tester) async {
    await tester.pumpWidget(const ShopSphereApp());

    expect(find.text('Welcome back!'), findsOneWidget);
  });
}
