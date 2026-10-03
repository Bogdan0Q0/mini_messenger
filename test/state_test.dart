import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_messenger/data/models/contact.dart';
import 'package:mini_messenger/data/models/user_account.dart';
import 'package:mini_messenger/data/repositories/contacts_repository.dart';
import 'package:mini_messenger/data/storage/contacts_file_storage.dart';
import 'package:mini_messenger/data/storage/media_storage.dart';
import 'package:mini_messenger/state/chat_list_controller.dart';
import 'package:mini_messenger/state/session_controller.dart';
import 'package:mini_messenger/state/theme_controller.dart';
import 'package:mini_messenger/data/storage/prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeController (Provider)', () {
    test('по умолчанию светлая тема', () async {
      final theme = ThemeController();
      await theme.load();
      expect(theme.isDark, isFalse);
    });

    test('setDark уведомляет слушателей и сохраняет выбор', () async {
      final theme = ThemeController();
      var notified = 0;
      theme.addListener(() => notified++);

      await theme.setDark(true);

      expect(theme.isDark, isTrue);
      expect(notified, 1);
      expect(await PrefsStorage().isDarkMode(), isTrue);

      final restored = ThemeController();
      await restored.load();
      expect(restored.isDark, isTrue);
    });
  });

  group('SessionController (Provider)', () {
    test('до загрузки состояние неизвестно, после — вход не выполнен',
        () async {
      final session = SessionController();
      expect(session.loggedIn, isNull);
      await session.load();
      expect(session.loggedIn, isFalse);
    });
  });

  group('ChatListController (Provider)', () {
    late Directory dir;

    setUp(() async {
      final user = UserAccount(
        id: 'u1',
        name: 'Тест',
        username: '@u1',
        email: 'u1@test.ru',
        password: '12345678',
      );
      SharedPreferences.setMockInitialValues({
        'current_user': jsonEncode(user.toJson()),
      });
      dir = await Directory.systemTemp.createTemp('chat_list_test_');
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    ChatListController makeController() => ChatListController(
          repo: ContactsRepository(
            fileStorage: ContactsFileStorage(directoryProvider: () async => dir),
            mediaStorage: MediaStorage(directoryProvider: () async => dir),
            remoteSource: () async => null,
          ),
        );

    test('load заполняет список и снимает признак загрузки', () async {
      final controller = makeController();
      expect(controller.loading, isTrue);

      await controller.load();

      expect(controller.loading, isFalse);
      expect(controller.chats.length, kFallbackContacts.length);
      expect(controller.chats.first.lastMessage, 'Начните диалог');
    });

    test('setQuery фильтрует чаты и уведомляет слушателей', () async {
      final controller = makeController();
      await controller.load();
      final first = controller.chats.first.contact;
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setQuery(first.name);

      expect(notified, 1);
      expect(controller.chats.every((c) => c.contact.matches(first.name)),
          isTrue);
      expect(controller.chats.any((c) => c.contact.id == first.id), isTrue);

      controller.setQuery('');
      expect(controller.chats.length, kFallbackContacts.length);
    });
  });
}
