import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_messenger/app.dart';
import 'package:mini_messenger/widgets/custom_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Экран логина отображается при запуске', (tester) async {
    await tester.pumpWidget(const MiniChatApp());
    await tester.pumpAndSettle();

    expect(find.text('MiniChat'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('Кастомный виджет CustomAvatar отображает инициалы',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CustomAvatar(initials: 'АП', color: Colors.blue),
      ),
    ));

    expect(find.text('АП'), findsOneWidget);
  });
}
