---
title: "Подключите агента через MCP — Mac · Командная строка (CLI)"
sidebar_label: "Подключите агента через MCP"
description: "Выберите доверенные папки и настройте клиент MCP."
pagination_prev: "platforms/macos-cli/verification"
pagination_next: "platforms/macos-cli/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Подключите агента через MCP — Mac · Командная строка (CLI)

[Все руководства платформы](../macos-cli.md) · [Установка и подключение считывателя](./setup.md)

Выберите доверенные папки и настройте клиент MCP.

В иллюстрациях используются вымышленные данные. Выполняйте действия в установленном приложении.

## Подключите MCP с явным доступом к файлам

Настройте локальный клиент совместимого протокола с абсолютным путём программы и выбранной доверенной папкой. Укажите существующую физическую папку. Корни, заявленные клиентом, не дают прав. Символические ссылки, обход пути и специальные файлы отклоняются. Без корней доступно только обнаружение. Используется stdio, а не сетевой сервис подписи. Лимит8МиБ; оригиналам XML нужен отдельный явно указанный корень.

<GuideScreenshot src="/img/guide/macos-cli/ru/mcp.svg" alt="5. Подключите MCP с явным доступом к файлам" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 58.5, "text": "Выберите установленную программу и ограниченную папку."}, {"text": "Запросите возможности, затем автономную проверку."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing
```

Начните с `capabilities` и `verify_document`. Вход: `{rootId,relativePath}`; не передавайте PIN или содержимое документа. Возвращаются минимальные метаданные. Клиент может передать их своим внешним сервисам. См. [настройку и правила MCP](https://esemnbun.md/packages/mcp.md).

```json
{
  "command": "/opt/homebrew/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/Users/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
