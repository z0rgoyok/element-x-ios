# Tich Connect для iOS

Приложение для `connect.tich.app`: переписка, зашифрованные файлы и push.
Исходная версия Element X — `release/26.10.6`, commit
`1621340a9dc9e1b539201f0709621f6849e99557`. Лицензии и attribution сохранены.

Собственный форк: `z0rgoyok/element-x-ios`. Изменения проходят ветку, PR,
проверки форка и merge. Deploy OS обслуживает проект `connect-ios`; ключи
Apple находятся в его SOPS и Keychain. Ключи не помещаются в приложение.

## Сборка

1. `swift run tools setup-project` устанавливает инструменты и генерирует проект.
2. Иконка Tich Connect хранится в `ElementX/Resources/AppIcon.icon`; CI проверяет её точный SHA256.
3. SwiftFormat закреплён на `0.64.0` и проверяется по SHA256.
4. После изменения `app.yml` или `target.yml` выполнить `xcodegen`.
5. Проверить unit tests и собрать архив схемы `ElementX`, конфигурация `Release`.
6. Выпускать только после подключения проверенной сборки нашего Rust SDK,
   проверки входа, E2EE сообщения, файла и push на физическом устройстве.

Bundle ID `app.tich.connect`; App Group `group.app.tich.connect`.
Расширения: `.nse` и `.shareextension`. Минимальная версия iOS — 18.5.
Регистрация участников проходит по приглашению на сайте; приложение использует
существующие логин и пароль.

## Транспорт и уведомления

Сетевой слой Matrix SDK реализует протокол `connect-transport v1`: мутации
Matrix передаются пакетами GET через Яндекс CDN, с проверкой идентификатора,
контрольной суммы и ответов. GET-запросы Matrix идут обычным HTTPS.
При неопределённом результате записи транспорт не создаёт новую операцию.
Для Tich Connect нативные звонки включены по умолчанию и используют LiveKit
из `org.matrix.msc4143.rtc_foci`.

Push требует отдельного APNs шлюза для нашего Bundle ID. Расширение NSE
использует ту же сборку SDK и общую защищённую сессию приложения. Apple выдаёт
Notification Filtering по отдельному запросу; до одобрения NSE работает без
этого restricted entitlement. В этом режиме зашифрованное RTC-уведомление
показывается как обычный push `Incoming call`, а не отправляется в CallKit.
После одобрения entitlement и флага
`TICH_HAS_NOTIFICATION_FILTERING_ENTITLEMENT` включается системный экран
входящего звонка. `ci_scripts/verify-tich-push.py` не допускает сборку, если
entitlement и compile-time режим расходятся.

Состояния выпуска фиксируются отдельно: исходники, тесты, архив, загрузка,
обработка Apple и доступность сборки в TestFlight.

## Закреплённый SDK и архив

Swift package `z0rgoyok/matrix-rust-components-swift`, версия
`26.10.21`, собирается из нашего Rust SDK
`7f90f583ce044af09f141d30b2037d91d99c942e`. Квитанция `tich-source.json`
в release связывает исходники и checksum бинарного XCFramework.

Workflow `Tich Connect archive` запускается на Xcode 27, импортирует
distribution identity, создаёт подписанный archive и App Store IPA. SwiftPM и
Xcode Compilation Cache восстанавливаются между запусками. Xcode
автоматически обновляет профили через App Store Connect API. Проверка требует
production APNs и App Group для приложения, NSE и ShareExtension.

При ручном запуске `upload_to_testflight=true` workflow дополнительно
загружает IPA через `altool` и сохраняет ответ Apple. Наличие IPA в артефакте
само по себе не подтверждает обработку сборки или её доступность тестерам.
