import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/app/app.dart';

void main() {
  testWidgets('ShopSphere app launches successfully', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShopSphereApp()));

    // Verify the initial splash screen renders.
    await tester.pump();

    expect(find.text('ShopSphere'), findsOneWidget);
  });
}
