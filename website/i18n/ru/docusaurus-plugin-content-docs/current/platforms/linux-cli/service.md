---
title: "Запустите службу браузера — Linux · Командная строка (CLI)"
sidebar_label: "Запустите службу браузера"
description: "Запускайте и останавливайте локальный мост или службу пользователя."
pagination_prev: "platforms/linux-cli/unattended"
pagination_next: "platforms/linux-cli/encrypt-password"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Запустите службу браузера — Linux · Командная строка (CLI)

[Все руководства платформы](../linux-cli.md) · [Установка и подключение считывателя](./setup.md)

Запускайте и останавливайте локальный мост или службу пользователя.

## Запустите локальное соединение с браузером

Держите bridge в переднем плане во время работы с сайтом на этом компьютере. По умолчанию loopback HTTP18480 и HTTPS18443. Не запускайте GUI bridge или MoldSign на тех же портах. Остановите Ctrl+C. Пакету нужна HTTPS-идентичность localhost. Для нативных диалогов согласия/PIN используйте приложение рабочего стола.

<GuideScreenshot src="/img/guide/linux-cli/ru/service.svg" alt="8. Запустите локальное соединение с браузером" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 23.8, "text": "Запустите локальный bridge браузера."}, {"x": 3, "y": 83.2, "text": "Завершите Ctrl+C после работы."}]} />

```sh
sudo systemctl enable --now pcscd.socket
esemnbun server
# Ctrl+C
```

---

Расширенная справка: macOS/Linux также дают `sign-hex <digestinfo_hex>` и `cms-for-hash <sha256_hex>`; Windows только sign-hex. Это инструменты разработчика, не подпись документов. Для поддержки укажите версии приложения/ОС, команду без секретов, код и вымышленный пример. Не прикладывайте PIN или конфиденциальные файлы.

<!-- file-protection-guides -->
