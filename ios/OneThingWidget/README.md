# iOS Widget Setup (One Thing — WidgetKit)

## 1. Создание extension
1. Открой `ios/Runner.xcworkspace` в Xcode.
2. `File → New → Target → Widget Extension`, имя: `OneThingWidget`.
3. Сними галочку "Include Live Activity" (не нужен для MVP).
4. Xcode спросит про схему — нажми "Activate".

## 2. Настройка App Group
1. В **Signing & Capabilities** главного таргета **Runner**:
   `+ Capability → App Groups` → добавь `group.com.onething.app`.
2. То же самое для таргета **OneThingWidgetExtension**.

## 3. Код виджета
1. Удали автосгенерированные файлы в папке `OneThingWidget/`
   (кроме `Info.plist` и `Assets.xcassets`, если созданы).
2. Скопируй туда:
   - `OneThingWidget.swift` (из репозитория: `ios/OneThingWidget/OneThingWidget.swift`)
   - `OneThingWidgetBundle.swift`
3. Убедись, что оба файла добавлены в target `OneThingWidgetExtension`.

## 4. URL scheme для тапов по чекбоксам
В `Info.plist` главного таргета (Runner) добавь:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.onething.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>onething</string>
        </array>
    </dict>
</array>
```

## 5. Сборка без подписи (MVP)
```bash
flutter build ios --no-codesign
```

## Как работает синхронизация
- Flutter-сторона пишет данные в App Group UserDefaults
  (`widget.tasks`, `widget.date`, `widget.counter`) через пакет `home_widget`
  и дергает `updateWidget()` → WidgetKit перечитывает timeline.
- Тап по чекбоксу открывает `onething://toggleTask?taskId=<id>`,
  Flutter обрабатывает deep link (в `main.dart`), переключает задачу
  в репозитории и обновляет данные виджета.
