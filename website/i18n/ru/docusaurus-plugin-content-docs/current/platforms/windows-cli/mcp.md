---
title: "Подключите агента через MCP — Windows · Командная строка (CLI)"
sidebar_label: "Подключите агента через MCP"
description: "Выберите доверенные папки и настройте клиент MCP."
pagination_prev: "platforms/windows-cli/verification"
pagination_next: "platforms/windows-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Подключите агента через MCP — Windows · Командная строка (CLI)

[Все руководства платформы](../windows-cli.md) · [Установка и подключение считывателя](./setup.md)

Выберите доверенные папки и настройте клиент MCP.

В иллюстрациях используются вымышленные данные. Выполняйте действия в установленном приложении.

## Подключите MCP с явным доступом к файлам

Настройте локальный клиент совместимого протокола с абсолютным путём программы и выбранной доверенной папкой. Укажите существующую физическую папку. Корни, заявленные клиентом, не дают прав. Символические ссылки, обход пути и специальные файлы отклоняются. Без корней доступно только обнаружение. Используется stdio, а не сетевой сервис подписи. Лимит8МиБ; оригиналам XML нужен отдельный явно указанный корень.

<GuideScreenshot src="/img/guide/windows-cli/ru/mcp.svg" alt="5. Подключите MCP с явным доступом к файлам" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 58.5, "text": "Выберите установленную программу и ограниченную папку."}, {"text": "Запросите возможности, затем автономную проверку."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

Начните с `capabilities` и `verify_document`. Вход: `{rootId,relativePath}`; не передавайте PIN или содержимое документа. Возвращаются минимальные метаданные. Клиент может передать их своим внешним сервисам. См. [настройку и правила MCP](https://esemnbun.md/packages/mcp.md). [Настройки и навыки для десяти ИИ-агентов](https://esemnbun.md/docs/integrations/mcp-agents/) (на английском).

```json
{
  "command": "C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe",
  "args": [
    "mcp",
    "--root",
    "documents=C:\\Users\\me\\Documents\\Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
