---
title: "Linux — руководства"
sidebar_label: "Linux"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/linux/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Linux — руководства

Выберите задачу. Для каждой есть отдельное краткое иллюстрированное руководство.

<GuideDirectory platform="linux" />
<GuideAnchorRedirect platform="linux" />

## Перед началом

Следуйте пронумерованным снимкам eSemnBun 0.2.6 для Linux. Это нативное приложение GTK с вымышленными людьми и примерами документов. Кружки добавлены в руководство; баннер демонстрации скрыт только в изолированных снимках для документации. Пример успешного состояния не доказывает настоящую подпись. Нажмите изображение для увеличения и выберите Исходный размер для мелких элементов.

Установите настольный пакет для вашей системы и архитектуры из раздела [Загрузки](/downloads/), затем откройте приложение из меню. Настольные DEB/RPM/Flatpak запускают графическое приложение; репозитории и архивы CLI устанавливают терминальные инструменты. См. [руководство Linux CLI](./linux-cli.md) для терминала и MCP. Ubuntu 24.04/Fedora — поддерживаемые настольные системы; проверяйте требования пакета. Нужны действующее поддерживаемое удостоверение, правильный PIN подписи, совместимый USB-считыватель и адаптер. NFC не поддерживается. Закрытый ключ остаётся на карте.

Нужны PC/SC и драйвер CCID. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Включите сокет: `sudo systemctl enable --now pcscd.socket`. Запускайте приложение в графической сессии; политика доступа через SSH может отличаться.
