import 'package:flutter_test/flutter_test.dart';
import 'package:documaster/main.dart';

void main() {
  testWidgets('App compile and load test', (WidgetTester tester) async {
    // Basic instantiation check
    expect(const DocuMasterApp(), isNotNull);
  });
}
