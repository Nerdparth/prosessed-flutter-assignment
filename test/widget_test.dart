import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/app/app.dart';

void main() {
  testWidgets('ShopSphere app launches successfully', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShopSphereApp()));

    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
  });
}
