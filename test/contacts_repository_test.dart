import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_messenger/data/models/contact.dart';
import 'package:mini_messenger/data/models/message.dart';
import 'package:mini_messenger/data/models/user_account.dart';
import 'package:mini_messenger/data/repositories/account_repository.dart';
import 'package:mini_messenger/data/repositories/contacts_repository.dart';
import 'package:mini_messenger/data/storage/contacts_file_storage.dart';
import 'package:mini_messenger/data/storage/media_storage.dart';
import 'package:mini_messenger/data/storage/prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserAccount account(String id) => UserAccount(
      id: id,
      name: 'Тест',
      username: '@$id',
      email: '$id@test.ru',
      password: '12345678',
    );

/// Заготовка SharedPreferences: пользователь [id] уже вошёл.
void signIn(String id, {Map<String, Object> extra = const {}}) {
  SharedPreferences.setMockInitialValues({
    'current_user': jsonEncode(account(id).toJson()),
    ...extra,
  });
}

void main() {
  late Directory dir;

  ContactsRepository makeRepo() => ContactsRepository(
        fileStorage: ContactsFileStorage(directoryProvider: () async => dir),
        mediaStorage: MediaStorage(directoryProvider: () async => dir),
        remoteSource: () async => null, // без сети: берём встроенный список
      );

  File jsonFile(String userId) =>
      File('${dir.path}${Platform.pathSeparator}contacts_$userId.json');

  List<dynamic> readJson(String userId) =>
      jsonDecode(jsonFile(userId).readAsStringSync()) as List<dynamic>;

  Message photoMessage(String path) => Message(
        id: 1,
        text: '',
        time: '12:00',
        outgoing: true,
        imagePath: path,
      );

  setUp(() async {
    signIn('u1');
    dir = await Directory.systemTemp.createTemp('contacts_test_');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  group('contacts_<id>.json', () {
    test('при первом входе создаётся файл пользователя', () async {
      final contacts = await makeRepo().fetchContacts();

      expect(contacts.length, kFallbackContacts.length);
      expect(readJson('u1').length, kFallbackContacts.length);
    });

    test('переименование записывается в JSON-файл', () async {
      await makeRepo().rename('1', 'Новое Имя');

      final saved = readJson('u1').cast<Map<String, dynamic>>();
      final entry = saved.firstWhere((m) => m['id'] == '1');
      expect(entry['name'], 'Новое Имя');
      expect(entry['initials'], 'НИ');

      // после «перезапуска» (новый репозиторий) имя читается из файла
      final reloaded = await makeRepo().fetchContacts();
      expect(reloaded.firstWhere((c) => c.id == '1').name, 'Новое Имя');
    });

    test('удаление убирает контакт из файла, переписку и фото', () async {
      final prefs = PrefsStorage();
      final photo = File(
          '${dir.path}${Platform.pathSeparator}media${Platform.pathSeparator}u1'
          '${Platform.pathSeparator}chat_2${Platform.pathSeparator}a.jpg')
        ..createSync(recursive: true);
      await prefs.saveMessages('2', [photoMessage(photo.path)]);
      await prefs.updateChatPreview('2', 'Фото', '12:00');

      await makeRepo().delete('2');

      final saved = readJson('u1').cast<Map<String, dynamic>>();
      expect(saved.any((m) => m['id'] == '2'), isFalse);
      expect(await prefs.loadMessages('2'), isEmpty);
      expect((await prefs.getChatInfo()).containsKey('2'), isFalse);
      expect(photo.existsSync(), isFalse);

      final reloaded = await makeRepo().fetchContacts();
      expect(reloaded.any((c) => c.id == '2'), isFalse);
    });

    test('findById возвращает null для удалённого контакта', () async {
      final repo = makeRepo();
      expect(await repo.findById('3'), isNotNull);
      await repo.delete('3');
      expect(await repo.findById('3'), isNull);
    });

    test('повреждённый файл пересоздаётся', () async {
      jsonFile('u1').writeAsStringSync('{ это не json');

      final contacts = await makeRepo().fetchContacts();

      expect(contacts.length, kFallbackContacts.length);
      expect(readJson('u1').length, kFallbackContacts.length);
    });

    test('правки старых версий переносятся в файл пользователя', () async {
      signIn('u1', extra: {
        'u_u1_deleted_ids': ['1'],
        'u_u1_name_overrides': jsonEncode({'2': 'Макс'}),
      });

      final contacts = await makeRepo().fetchContacts();

      expect(contacts.any((c) => c.id == '1'), isFalse);
      expect(contacts.firstWhere((c) => c.id == '2').name, 'Макс');
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey('u_u1_deleted_ids'), isFalse);
      expect(p.containsKey('u_u1_name_overrides'), isFalse);
    });
  });

  group('данные разных пользователей', () {
    test('контакты, переписка и аватар не пересекаются', () async {
      final repo = makeRepo();
      final prefs = PrefsStorage();

      // пользователь u1 удаляет контакт, пишет сообщение и ставит аватар
      await repo.delete('1');
      await prefs.saveMessages('2', [photoMessage('/tmp/x.jpg')]);
      await prefs.updateChatPreview('2', 'Фото', '12:00');
      await prefs.setAvatarPath('/tmp/avatar.jpg');

      // входит новый пользователь u2
      await prefs.setCurrentUser(account('u2'));

      expect((await repo.fetchContacts()).length, kFallbackContacts.length);
      expect(await prefs.loadMessages('2'), isEmpty);
      expect(await prefs.getChatInfo(), isEmpty);
      expect(await prefs.getAvatarPath(), isNull);

      // u1 возвращается — его данные на месте
      await prefs.setCurrentUser(account('u1'));
      expect((await repo.fetchContacts()).any((c) => c.id == '1'), isFalse);
      expect(await prefs.loadMessages('2'), hasLength(1));
      expect(await prefs.getAvatarPath(), '/tmp/avatar.jpg');
    });

    test('миграция отдаёт старые общие данные последнему вошедшему', () async {
      SharedPreferences.setMockInitialValues({
        // аккаунты старой версии — без id
        'registered_users': [
          jsonEncode({
            'name': 'Старый',
            'username': '@old',
            'email': 'old@test.ru',
            'password': '12345678',
          }),
        ],
        'current_user': jsonEncode({
          'name': 'Старый',
          'username': '@old',
          'email': 'old@test.ru',
          'password': '12345678',
        }),
        'messages_1': [jsonEncode(photoMessage('/tmp/old.jpg').toJson())],
        'chat_info': jsonEncode({
          '1': {'text': 'Фото', 'time': '12:00', 'ts': 1}
        }),
        'avatar_path': '/tmp/old_avatar.jpg',
      });
      final prefs = PrefsStorage();

      await prefs.migrateLegacyData();

      // владелец видит свои данные
      expect(await prefs.loadMessages('1'), hasLength(1));
      expect((await prefs.getChatInfo()).containsKey('1'), isTrue);
      expect(await prefs.getAvatarPath(), '/tmp/old_avatar.jpg');

      // общих ключей больше нет
      final p = await SharedPreferences.getInstance();
      expect(p.containsKey('messages_1'), isFalse);
      expect(p.containsKey('chat_info'), isFalse);
      expect(p.containsKey('avatar_path'), isFalse);

      // новый пользователь старых данных не видит
      final fresh = UserAccount.create(
        name: 'Новый',
        username: '@new',
        email: 'new@test.ru',
        password: '12345678',
      );
      expect(await prefs.registerUser(fresh), isTrue);
      await prefs.setCurrentUser(fresh);
      expect(await prefs.loadMessages('1'), isEmpty);
      expect(await prefs.getChatInfo(), isEmpty);
      expect(await prefs.getAvatarPath(), isNull);
    });
  });

  group('аккаунты', () {
    test('правка профиля не принимает занятые email и username', () async {
      final prefs = PrefsStorage();
      await prefs.registerUser(account('u1'));
      await prefs.registerUser(account('u2'));
      await prefs.setCurrentUser(account('u1'));

      final taken = await prefs.updateCurrentUser(
          name: 'Тест', email: 'u2@test.ru', username: '@u1');
      expect(taken, isNotNull);

      final ok = await prefs.updateCurrentUser(
          name: 'Тест', email: 'new@test.ru', username: '@u1');
      expect(ok, isNull);
      expect((await prefs.getCurrentUser())!.email, 'new@test.ru');
      expect((await prefs.getCurrentUser())!.id, 'u1');
    });

    test('удаление профиля стирает аккаунт и все его данные', () async {
      final prefs = PrefsStorage();
      await prefs.registerUser(account('u1'));
      await prefs.registerUser(account('u2'));
      await prefs.setLoggedIn(true);

      // данные пользователя u1: переписка, аватар, файл контактов, фото
      await prefs.saveMessages('1', [photoMessage('/tmp/a.jpg')]);
      await prefs.updateChatPreview('1', 'Фото', '12:00');
      await prefs.setAvatarPath('/tmp/avatar.jpg');
      await makeRepo().fetchContacts();
      final sep = Platform.pathSeparator;
      final photo = File('${dir.path}${sep}media${sep}u1${sep}chat_1${sep}a.jpg')
        ..createSync(recursive: true);

      // данные пользователя u2 должны остаться нетронутыми
      await prefs.setCurrentUser(account('u2'));
      await prefs.saveMessages('1', [photoMessage('/tmp/b.jpg')]);
      await prefs.setCurrentUser(account('u1'));

      await AccountRepository(
        prefs: prefs,
        contactsFile: ContactsFileStorage(directoryProvider: () async => dir),
        media: MediaStorage(directoryProvider: () async => dir),
      ).deleteCurrentAccount();

      expect(await prefs.getCurrentUser(), isNull);
      expect(await prefs.isLoggedIn(), isFalse);
      expect(await prefs.loginUser('@u1', '12345678'), isNull);
      final p = await SharedPreferences.getInstance();
      expect(p.getKeys().where((k) => k.startsWith('u_u1_')), isEmpty);
      expect(jsonFile('u1').existsSync(), isFalse);
      expect(photo.existsSync(), isFalse);

      expect(await prefs.loginUser('@u2', '12345678'), isNotNull);
      await prefs.setCurrentUser(account('u2'));
      expect(await prefs.loadMessages('1'), hasLength(1));
    });
  });
}
