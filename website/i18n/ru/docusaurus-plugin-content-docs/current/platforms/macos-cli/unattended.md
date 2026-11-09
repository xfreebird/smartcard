---
title: "Настройте подпись без присутствия — Mac · Командная строка (CLI)"
sidebar_label: "Настройте подпись без присутствия"
description: "Закрепите сертификат, выберите источник секрета и ограничьте вывод."
pagination_prev: "platforms/macos-cli/approval"
pagination_next: "platforms/macos-cli/service"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Настройте подпись без присутствия — Mac · Командная строка (CLI)

[Все руководства платформы](../macos-cli.md) · [Установка и подключение считывателя](./setup.md) · [Подключите агента через MCP](./mcp.md)

Закрепите сертификат, выберите источник секрета и ограничьте вывод.

## Явно настройте подпись без присутствия

Этот расширенный режим подписывает без диалога на каждый документ. Отдельно подготовьте секреты, закрепите точный SHA-256 DER сертификата и создайте приватную папку результатов. Используйте ссылки на источники, а не PIN. Сертификат проверяется до чтения секрета и VERIFY. Проверьте карту и источник в своей установке до применения в работе.

<GuideScreenshot src="/img/guide/macos-cli/ru/unattended.svg" alt="7. Явно настройте подпись без присутствия" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 27.4, "text": "Укажите ограниченный вход и приватную папку результатов."}, {"x": 3, "y": 80.6, "text": "Закрепите сертификат и выберите ссылку источника секрета."}]} />

```sh
esemnbun-mcp \
  --root documents=/Users/me/Documents/Signing \
  --allow-unattended-signing \
  --signing-certificate-sha256 <CERTIFICATE_SHA256> \
  --signing-output-directory /Users/me/PrivateOutput \
  --pin-source keychain:service:account
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` или `onepassword:op://Vault/Item/field`. Linux: `secret-service:service:account`, окружение или1Password. Windows: `credential:eSemnBun-Automation`, окружение или1Password с абсолютным путём op.exe. Отдельно подготовленная запись Keychain/Credential Manager должна разрешать нужный доступ; биометрическое хранилище приложения не ослабляется. Войдите в1Password вне MCP.

Перед запуском замените `<CERTIFICATE_SHA256>` точными64шестнадцатеричными цифрами. Папка должна существовать: macOS/Linux требуют владельца-пользователя и0700; ACL Windows допускает только пользователя, SYSTEM и Administrators.

Перед подписью создаётся `.unattended-signing-lock` в папке результатов. Неверный PIN, прерывание или неопределённая ошибка оставляют маркер и блокируют повтор. Проверьте результат и состояние карты, осознанно устраните неопределённость и только затем удалите маркер и перезапустите. Не автоматизируйте удаление/повтор. Отмена или тайм-аут не доказывают отсутствие подписи.
