import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:picme/src/app/picme_app.dart';

void main() {
  testWidgets('app boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PicmeApp());
    await tester.pump();
    expect(find.byType(WidgetsApp), findsWidgets);
  });
}
