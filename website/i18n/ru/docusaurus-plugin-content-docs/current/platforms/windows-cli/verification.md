---
title: "Проверьте через MCP — Windows · Командная строка (CLI)"
sidebar_label: "Проверьте через MCP"
description: "Проверьте PDF или XML, сведения о подписанте и сертификате."
pagination_prev: "platforms/windows-cli/setup"
pagination_next: "platforms/windows-cli/mcp"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Проверьте через MCP — Windows · Командная строка (CLI)

[Все руководства платформы](../windows-cli.md) · [Установка и подключение считывателя](./setup.md)

Проверьте PDF или XML, сведения о подписанте и сертификате.

## Проверьте документ и результат

Автономная проверка Windows доступна через MCP verify_document, не обычную команду verify. Настройте явный корень и `{rootId,relativePath}`; анализируйте целостность, подпись, цепочку. Для отсутствующих оригиналов нужен отдельный корень. Карта/PIN не используются; текущий отзыв не проверяется.

<GuideScreenshot src="/img/guide/windows-cli/ru/verification.svg" alt="руководство командной строки" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 18.3, "text": "Запустите сервер MCP с выбранной папкой."}, {"x": 3, "y": 41.2, "text": "В клиенте MCP выберите инструмент verify_document."}, {"x": 3, "y": 64.1, "text": "Передайте эти параметры и проверьте целостность, подпись и цепочку. Это пример, а не полученный результат."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
