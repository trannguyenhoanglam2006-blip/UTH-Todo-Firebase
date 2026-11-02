import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test giao diện đơn giản không cần Firebase kết nối Internet.
void main() {
  testWidgets('Hiển thị văn bản UTH Todo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('UTH Todo'))));
    expect(find.text('UTH Todo'), findsOneWidget);
  });
}
