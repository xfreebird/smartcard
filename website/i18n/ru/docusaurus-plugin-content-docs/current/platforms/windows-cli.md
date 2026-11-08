---
title: "Windows · Командная строка (CLI) — руководства"
sidebar_label: "Windows · Командная строка (CLI)"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/windows-cli/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Windows · Командная строка (CLI) — руководства

Выберите задачу. Для каждой есть отдельное краткое иллюстрированное руководство.

<GuideDirectory platform="windows-cli" />
<GuideAnchorRedirect platform="windows-cli" />

## Перед началом

Следуйте пронумерованным примерам для конкретной цели. Команды остаются на английском. Панели показывают учебные команды, а не реальную подпись картой. Только результаты возможностей и проверки неподписанного файла получены локально; настоящие PIN, карта и хранилище секретов не использовались.

Для операций с картой нужны поддерживаемое электронное удостоверение, правильный PIN, совместимый USB-считыватель и адаптер. NFC не поддерживается. Для проверки не нужны карта или PIN. Сохраняйте оригиналы. Закрытый ключ остаётся на карте.

:::info
CLI Windows сейчас поддерживает help, capabilities, readers, cert, sign-hex, mcp. Обычные sign/xades/verify/server/cms-for-hash не реализованы. Для документов используйте настольное приложение или отдельно настроенные инструменты MCP проверки/подписи без присутствия. В Windows MCP нет брокера подтверждения настольного приложения. Не предполагайте одинаковые команды с macOS/Linux.
:::
