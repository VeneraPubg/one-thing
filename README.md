# One Thing

Минималистичное todo-приложение: **не больше 3 задач на день**.
Меньше задач — больше внимания.

## Возможности
- **Сегодня** — ровно 3 слота, счётчик «X из 3», мягкое зачёркивание выполненных.
- **Когда-нибудь** — отложенные идеи; кнопка «Взять на сегодня» срабатывает только при свободном слоте, иначе предлагается замена.
- **Итог дня** — вечерний пуш (по умолчанию 20:00, настраивается): «На завтра» / «В когда-нибудь» / «Удалить» для каждой несделанной задачи.
- **Настройки** — время пуша, поведение несделанных задач по умолчанию, тема (светлая/тёмная/системная).
- **Виджет на главный экран** (Android AppWidget + iOS WidgetKit): 3 задачи с чекбоксами и счётчиком.

## Стек
| Слой | Выбор | Почему |
|---|---|---|
| Состояние | Riverpod 2.x | доступ без BuildContext (фон. коллбэки виджета/пушей), лёгкие override в тестах |
| БД | Hive 2.x | чистый Dart без нативных биндингов, мгновенное открытие box в фоне |
| Навигация | go_router 14 | `StatefulShellRoute.indexedStack` для табов, deep links из пуша и виджета |
| Уведомления | flutter_local_notifications + timezone | ежедневный повтор `matchDateTimeComponents` |
| Виджет | home_widget | единый мост для Android и iOS |

## Запуск

```bash
flutter pub get
flutter run
```

## Сборка

```bash
# Android
flutter build apk --release

# iOS (без подписи)
flutter build ios --no-codesign
```

### Подключение виджета
- **Android** — код AppWidget уже в `android/app/src/main/` (`OneThingWidgetProvider.kt` + layout). Ничего дополнительного делать не нужно.
- **iOS** — см. `ios/OneThingWidget/README.md`: создать Widget Extension в Xcode, добавить App Group `group.com.onething.app` и URL scheme `onething`.

## Тесты

```bash
flutter test
```

Покрыто: жёсткий лимит 3 задачи (репозиторий), перенос «на завтра» / «в когда-нибудь», замена задач, подсчёт итога дня, модель Task.

## Как добавить новый язык

1. Создай файл `lib/l10n/app_<код>.arb` (например, `app_de.arb`), скопировав все ключи из `lib/l10n/app_ru.arb`.
2. Переведи значения (ключи и `@`-метаданные не трогай).
3. Добавь локаль в `supportedLocales` в `lib/main.dart`:
   ```dart
   supportedLocales: const [
     Locale('ru'),
     Locale('en'),
     Locale('de'), // новая
   ],
   ```
4. В `lib/main.dart` (опционально) поменяй `locale:` для форсирования или убери строку — тогда язык определится по системе.
5. `flutter gen-l10n` (или просто `flutter run`) — файлы локализации сгенерируются автоматически.

## Структура

```
lib/
  main.dart            # инициализация Hive, сервисов, провайдеров
  app/                 # роутер (go_router), тема, l10n
  features/
    today/             # экран «Сегодня», добавление, диалог лимита
    someday/           # отложенные задачи, перенос/замена
    summary/           # итог дня
    settings/          # настройки (пуш, поведение, тема)
  data/                # Hive-модели, адаптеры, репозитории
  services/            # уведомления, мост виджета, синхронизация
  shared/              # UI-kit: TaskSlotCard, кнопки, поля
test/unit/             # лимит 3, переносы, итог дня, модель
```

## Бизнес-инвариант
Лимит 3 задачи enforced в `TaskRepository` (`addTaskToToday`, `moveTaskToToday` → `LimitExceededException`) — на уровне данных, не только UI.
