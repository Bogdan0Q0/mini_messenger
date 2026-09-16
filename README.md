# MiniChat

Мини-мессенджер на Flutter — учебный проект по дисциплине
«Технологии разработки мобильных приложений».

---

## О проекте

MiniChat — кроссплатформенное мобильное приложение для обмена
сообщениями. Реализовано на Flutter (Dart) с использованием
Material 3 и локального хранилища SharedPreferences.

Приложение работает на Android и iOS, поддерживает авторизацию,
список чатов, диалоги с сохранением истории, редактирование
профиля и загрузку данных с внешнего REST API.

---

## Функционал

- Авторизация и регистрация с валидацией полей.
- Список чатов с загрузкой пользователей с публичного API.
- Диалог с пузырями сообщений и сохранением истории.
- Новый чат — выбор собеседника из списка контактов.
- Профиль — редактирование имени и email.
- Выход из аккаунта с возвратом на экран логина.
- Хранение данных через shared_preferences.
- Сетевое взаимодействие через http.
- Валидация ввода на всех формах.
- Обфускация release-сборки.

---

## Экраны

| Номер | Экран | Файл | Описание |
|-------|-------|------|----------|
| 1 | Авторизация | lib/screens/login_screen.dart | Вход по email/username и паролю |
| 2 | Регистрация | lib/screens/register_screen.dart | Создание аккаунта |
| 3 | Список чатов | lib/screens/chat_list_screen.dart | Диалоги, поиск, FAB нового чата |
| 4 | Диалог | lib/screens/dialog_screen.dart | Переписка, отправка сообщений |
| 5 | Новый чат | lib/screens/new_chat_screen.dart | Выбор контакта |
| 6 | Профиль | lib/screens/profile_screen.dart | Редактирование профиля, выход |

---

## Архитектура

Проект организован по слоям (MVVM-подобная архитектура):

    lib/
    |-- main.dart                  точка входа
    |-- app.dart                   MaterialApp + AuthGate
    |-- theme/
    |   `-- app_theme.dart         цвета и тема
    |-- data/
    |   |-- models/                модели данных
    |   |   |-- contact.dart
    |   |   `-- message.dart
    |   |-- repositories/          работа с сетью
    |   |   `-- contacts_repository.dart
    |   `-- storage/               работа с локальным хранилищем
    |       `-- prefs_storage.dart
    |-- widgets/                   переиспользуемые компоненты
    |   |-- custom_avatar.dart
    |   |-- message_bubble.dart
    |   |-- chat_tile.dart
    |   |-- primary_button.dart
    |   |-- app_text_field.dart
    |   |-- search_field.dart
    |   `-- nav_header.dart
    `-- screens/                   экраны приложения
        |-- login_screen.dart
        |-- register_screen.dart
        |-- chat_list_screen.dart
        |-- dialog_screen.dart
        |-- new_chat_screen.dart
        `-- profile_screen.dart

### Слои

- Presentation (screens + widgets) — UI, отображение данных.
- Domain (models) — модели Contact, Message.
- Data (repositories + storage) — источник данных:
  - ContactsRepository — загрузка пользователей с REST API.
  - PrefsStorage — обёртка над shared_preferences.

Состояние хранится в StatefulWidget (аналог ViewModel в MVVM).

---

## Кастомные UI-компоненты

Собственные виджеты, разработанные с нуля:

### 1. CustomAvatar (lib/widgets/custom_avatar.dart)

Круглый аватар с инициалами пользователя и настраиваемым
цветом фона. Используется в списке чатов, диалоге и профиле.

### 2. MessageBubble (lib/widgets/message_bubble.dart)

Пузырь сообщения с асимметричными скруглениями (хвостик),
разным цветом для входящих и исходящих, отображением времени.

### 3. ChatTile (lib/widgets/chat_tile.dart)

Карточка чата с динамическим состоянием: при наличии
непрочитанных сообщений фон подсвечивается акцентным цветом
и появляется бейдж.

### Дополнительно

- PrimaryButton — кнопка с валидацией состояния.
- AppTextField — поле с иконкой показать/скрыть пароль.
- SearchField — поле поиска.
- NavHeader — верхняя навигационная панель.

---

## Технологии

- Flutter 3.47.4 / Dart 3.13.3
- Material 3 — дизайн-система
- shared_preferences ^2.3.2 — локальное хранилище
- http ^1.2.2 — сетевые запросы
- flutter_lints — статический анализ кода

---

## Установка и запуск

### Требования

- Flutter SDK 3.47 и выше
- Android Studio (для Android) или Xcode (для iOS)
- Эмулятор или реальное устройство

### Шаги

1. Клонировать проект:

       git clone https://github.com/username/mini_messenger.git
       cd mini_messenger

2. Установить зависимости:

       flutter pub get

3. Запустить приложение:

       flutter run

4. Выбрать устройство (Android-эмулятор / iOS-симулятор / Chrome).

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

---

## Скриншоты

| Экран | Скриншот |
|-------|----------|
| Авторизация | docs/screenshots/login.png |
| Регистрация | docs/screenshots/register.png |
| Список чатов | docs/screenshots/chat_list.png |
| Диалог | docs/screenshots/dialog.png |
| Новый чат | docs/screenshots/new_chat.png |
| Профиль | docs/screenshots/profile.png |

(Скриншоты нужно сделать с эмулятора и положить в папку
docs/screenshots/.)

---

## Автор

ФИО: Кривченко Богдан и Майбуров Максим
Группа: заполнить
Дисциплина: Технологии разработки мобильных приложений
Год: 2026

---

## Лицензия

Учебный проект. Свободное использование в образовательных целях.
