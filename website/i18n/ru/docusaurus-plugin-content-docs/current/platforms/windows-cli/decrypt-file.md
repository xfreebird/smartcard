---
title: "Расшифруйте полученный файл — Windows · Командная строка (CLI)"
sidebar_label: "Расшифруйте полученный файл"
description: "Расшифруйте полученный файл"
pagination_prev: "platforms/windows-cli/encrypt-certificate"
pagination_next: "platforms/windows-cli/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Расшифруйте полученный файл — Windows · Командная строка (CLI)

[Все руководства платформы](../windows-cli.md) · [Установка и подключение считывателя](./setup.md)

Расшифруйте полученный файл

## Расшифруйте полученный файл

Уточните у отправителя метод. Для файла с паролем получите пароль отдельно. Для файла с сертификатом подключите соответствующую поддерживаемую карту и считыватель; нужны ключ шифрования и PIN. Другая карта или карта только для подписи не подойдёт.

Учебный пример команды — операция не выполнялась.

<GuideScreenshot src="/img/guide/windows-cli/ru/protect-decrypt.svg" alt="Расшифруйте полученный файл" steps={[{"x": 20, "y": 25, "text": "Выполните команду со своими файлами. Используйте новый путь результата. Вводите секреты только в скрытом приглашении; замените SHA256 полным отпечатком сертификата шифрования."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Откройте и проверьте сохранённый результат. Совместимое с MoldSign шифрование не удостоверяет содержимое: успешная расшифровка сама по себе не доказывает целостность или правильность пароля.
