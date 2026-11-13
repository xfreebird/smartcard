---
title: "Альтернатива MoldSign для Linux — электронная подпись"
description: "eSemnBun для Linux: подпись с ID-картой Молдовы, приложение GNOME, USB-считыватель PC/SC, проверка PDF, подключение браузера и CLI/MCP."
sidebar_label: "Linux"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/linux/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Альтернатива MoldSign для Linux — электронная подпись

**eSemnBun — независимая альтернатива MoldSign для Linux.** Нативное приложение GNOME подписывает PDF и XAdES совместимой ID-картой Молдовы через USB-считыватель, проверяет файлы и обрабатывает запросы совместимых сайтов. Настольные DEB, RPM и Flatpak отличаются от [инструментов Linux CLI и MCP](./linux-cli.md). Для считывателя нужны служба PC/SC и драйвер CCID. eSemnBun не связан со STISC.

Выберите задачу. Для каждой есть отдельное краткое иллюстрированное руководство.

<GuideDirectory platform="linux" />
<GuideAnchorRedirect platform="linux" />

## Перед началом

Следуйте пронумерованным снимкам eSemnBun 0.2.6 для Linux. Нажмите изображение для увеличения и выберите Исходный размер для мелких элементов.

Установите настольный пакет для вашей системы и архитектуры из раздела [Загрузки](/downloads/), затем откройте приложение из меню. Настольные DEB/RPM/Flatpak запускают графическое приложение; репозитории и архивы CLI устанавливают терминальные инструменты. См. [руководство Linux CLI](./linux-cli.md) для терминала и MCP. Ubuntu 24.04/Fedora — поддерживаемые настольные системы; проверяйте требования пакета. Нужны действующее поддерживаемое удостоверение, правильный PIN подписи, совместимый USB-считыватель и адаптер. NFC не поддерживается. Закрытый ключ остаётся на карте.

Нужны PC/SC и драйвер CCID. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Включите сокет: `sudo systemctl enable --now pcscd.socket`. Запускайте приложение в графической сессии; политика доступа через SSH может отличаться.
