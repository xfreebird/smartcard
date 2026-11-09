---
title: "Зашифруйте файл паролем — Mac · Командная строка (CLI)"
sidebar_label: "Зашифруйте файл паролем"
description: "Зашифруйте файл паролем"
pagination_prev: "platforms/macos-cli/service"
pagination_next: "platforms/macos-cli/encrypt-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Зашифруйте файл паролем — Mac · Командная строка (CLI)

[Все руководства платформы](../macos-cli.md) · [Установка и подключение считывателя](./setup.md)

Зашифруйте файл паролем

## Зашифруйте файл паролем

Карта не нужна. Создайте пароль для файла и передайте получателю по отдельному доверенному каналу. Это не PIN карты. Шифрование создаёт отдельный файл; сохраните оригинал до проверки результата.

Учебный пример команды — операция не выполнялась.

<GuideScreenshot src="/img/guide/macos-cli/ru/protect-password.svg" alt="Зашифруйте файл паролем" steps={[{"x": 20, "y": 25, "text": "Выполните команду со своими файлами. Используйте новый путь результата. Вводите секреты только в скрытом приглашении; замените SHA256 полным отпечатком сертификата шифрования."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc
```
