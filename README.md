# MiniChat

Мини-мессенджер на Flutter — учебный проект по дисциплине
«Технологии разработки мобильных приложений».

---

## О проекте

MiniChat — кроссплатформенное мобильное приложение для обмена
сообщениями. Реализовано на Flutter (Dart) с использованием
Material 3 и локального хранилища SharedPreferences.

Приложение работает на Android и iOS, поддерживает регистрацию
и авторизацию, список чатов с сортировкой по последнему
взаимодействию, переписку с авто-ответами, отправку фото,
редактирование профиля и загрузку данных с внешнего REST API.

---

## Функционал

### Аккаунт и авторизация
- Регистрация с валидацией полей (имя, @username, email, пароль).
- Проверка уникальности email и username при регистрации.
- Вход только для зарегистрированных пользователей.
- Хранение нескольких аккаунтов на устройстве.

### Профиль
- Редактирование имени, @username и email.
- Смена аватарки через галерею телефона (image_picker).
- Переключатель тёмной темы.
- Выход из аккаунта.

### Чаты
- Загрузка контактов с публичного REST API.
- Поиск по имени и @username в списке чатов и в «Новом чате».
- Сортировка чатов: последний открытый — наверху.
- Превью последнего сообщения и время.

### Диалог
- Пузыри сообщений с асимметричными скруглениями.
- Авто-ответы собеседника через 1–2 секунды.
- Индикатор «печатает...».
- Отправка фото из галереи (скрепка).
- Меню (три точки):
  - **Переименовать** контакт (сохраняется в prefs).
  - **Удалить** контакт и всю переписку.

### Хранение и сеть
- Локальное хранилище: SharedPreferences (логин, профиль,
  аватар, тема, история сообщений, удалённые ID, переименования,
  метаданные чатов).
- Сетевое взаимодействие через http.
- Fallback: если API недоступен — используется встроенный список.

### Сборка
- Обфускация release-сборки.
- Юнит-тесты.

---

## Экраны

| Номер | Экран | Файл | Описание |
|-------|-------|------|----------|
| 1 | Авторизация | lib/screens/login_screen.dart | Вход по email или @username |
| 2 | Регистрация | lib/screens/register_screen.dart | Создание аккаунта |
| 3 | Список чатов | lib/screens/chat_list_screen.dart | Диалоги, поиск, сортировка |
| 4 | Диалог | lib/screens/dialog_screen.dart | Переписка, фото, меню |
| 5 | Новый чат | lib/screens/new_chat_screen.dart | Выбор контакта с поиском |
| 6 | Профиль | lib/screens/profile_screen.dart | Профиль, аватар, тема |

---

## Архитектура

Проект организован по слоям (MVVM-подобная архитектура):

    lib/
    |-- main.dart                       точка входа
    |-- app.dart                        MaterialApp + AuthGate
    |-- theme/
    |   `-- app_theme.dart              цвета, тема (светлая/тёмная)
    |-- data/
    |   |-- models/
    |   |   |-- contact.dart            модель контакта
    |   |   |-- message.dart            модель сообщения
    |   |   `-- user_account.dart       модель пользователя
    |   |-- repositories/
    |   |   `-- contacts_repository.dart  загрузка с REST API
    |   `-- storage/
    |       `-- prefs_storage.dart      SharedPreferences
    |-- widgets/
    |   |-- custom_avatar.dart          аватар с фото или инициалами
    |   |-- message_bubble.dart         пузырь (текст + фото)
    |   |-- chat_tile.dart              карточка чата
    |   |-- primary_button.dart
    |   |-- app_text_field.dart
    |   |-- search_field.dart
    |   `-- nav_header.dart
    `-- screens/
        |-- login_screen.dart
        |-- register_screen.dart
        |-- chat_list_screen.dart
        |-- dialog_screen.dart
        |-- new_chat_screen.dart
        `-- profile_screen.dart

### Слои

- Presentation (screens + widgets) — UI и обработка событий.
- Domain (models) — модели Contact, Message, UserAccount.
- Data (repositories + storage) — источники данных:
  - ContactsRepository — REST API с fallback.
  - PrefsStorage — обёртка над SharedPreferences.

Состояние хранится в StatefulWidget (аналог ViewModel в MVVM).

---

## Кастомные UI-компоненты

Собственные виджеты, разработанные с нуля:

### 1. CustomAvatar (lib/widgets/custom_avatar.dart)
Круглый аватар. Если задан путь к фото — показывает его
через Image.file. Иначе — инициалы на цветном фоне.
Используется в списке чатов, диалоге и профиле.

### 2. MessageBubble (lib/widgets/message_bubble.dart)
Пузырь сообщения с асимметричными скруглениями. Поддерживает
текст и изображение. Разные цвета для входящих и исходящих.

### 3. ChatTile (lib/widgets/chat_tile.dart)
Карточка чата с динамической подсветкой непрочитанных
и бейджем количества.

### Дополнительно
- PrimaryButton — основная кнопка.
- AppTextField — поле с показать/скрыть пароль.
- SearchField — поле поиска.
- NavHeader — верхняя навигационная панель.

---

## Технологии

- Flutter 3.47.4 / Dart 3.13.3
- Material 3 — дизайн-система
- shared_preferences ^2.3.2 — локальное хранилище
- http ^1.2.2 — сетевые запросы
- image_picker ^1.1.2 — выбор фото из галереи
- flutter_lints — статический анализ

---

## Установка и запуск

### Требования
- Flutter SDK 3.47 и выше
- Android Studio (для Android) или Xcode (для iOS)
- Эмулятор или реальное устройство

### Шаги

1. Клонировать проект:

       git clone https://github.com/Bogdan0Q0/mini_messenger.git
       cd mini_messenger

2. Установить зависимости:

       flutter pub get

3. Для iOS — установить pods:

       cd ios && pod install && cd ..

4. Запустить приложение:

       flutter run

5. Выбрать устройство (Android-эмулятор / iOS-симулятор / Chrome).

---

## Сборка релиза с обфускацией

### Android (APK)

    flutter build apk --release --obfuscate --split-debug-info=build/debug-info

Готовый APK: build/app/outputs/flutter-apk/app-release.apk

### iOS (IPA)

    flutter build ios --release --obfuscate --split-debug-info=build/debug-info

Флаг --obfuscate переименовывает классы и методы в коде Dart,
а --split-debug-info выносит отладочную информацию в отдельную
папку — это защищает приложение от реверс-инжиниринга.

---

## Тестирование

Запуск тестов:

    flutter test

В проекте реализованы 2 юнит-теста:

1. Проверка отображения экрана логина при запуске.
2. Проверка виджета CustomAvatar на отображение инициалов.

Функциональное тестирование проведено вручную по всем сценариям:
регистрация, вход, поиск, отправка текста и фото, авто-ответы,
переименование, удаление, смена темы, смена аватарки.

---

## Скриншоты

| Экран | Файл |
|-------|------|
| Авторизация | docs/screenshots/login.png |
| Регистрация | docs/screenshots/register.png |
| Список чатов | docs/screenshots/chat_list.png |
| Диалог | docs/screenshots/dialog.png |
| Новый чат | docs/screenshots/new_chat.png |
| Профиль | docs/screenshots/profile.png |

(Скриншоты нужно снять с эмулятора и положить в папку
docs/screenshots/.)

---

## Автор

ФИО: Кривченко и Майбуров О731Б
Дисциплина: Технологии разработки мобильных приложений
Год: 2026

---

## Лицензия

Учебный проект. Свободное использование в образовательных целях.
