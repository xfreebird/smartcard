---
title: "Подпишите документы — Mac · Командная строка (CLI)"
sidebar_label: "Подпишите документы"
description: "Добавьте файлы, выберите формат и штамп, подтвердите и сохраните результат."
pagination_prev: "platforms/macos-cli/setup"
pagination_next: "platforms/macos-cli/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Подпишите документы — Mac · Командная строка (CLI)

[Все руководства платформы](../macos-cli.md) · [Установка и подключение считывателя](./setup.md)

Добавьте файлы, выберите формат и штамп, подтвердите и сохраните результат.

## Подпишите PDF или создайте XML-подпись

PAdES-T встраивает подпись и метку времени в PDF. Без пути результата создаётся отдельный `-semnat.pdf`; существующий файл не перезаписывается. XAdES по умолчанию отделённый XML с SHA-256: храните неизменный оригинал вместе с XML. BES без метки времени, T с меткой, C с дополнительными ссылками сертификатов/отзыва. `--enveloping` нужен, когда получатель требует оригинал внутри XML. Форматам с меткой нужна сеть; C получает также сведения статуса.

<GuideScreenshot src="/img/guide/macos-cli/ru/sign.svg" alt="3. Подпишите PDF или создайте XML-подпись" caption="Учебный пример команды. Скопируйте команды ниже, заменив пути и имя считывателя." steps={[{"x": 3, "y": 23.8, "text": "Запустите подпись PDF и введите PIN в скрытом запросе."}, {"x": 3, "y": 53.5, "text": "Создайте уровень XML, нужный получателю."}, {"x": 3, "y": 83.2, "text": "Включайте оригинал в XML только при необходимости."}]} />

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf
esemnbun xades XAdES-T Declaration.txt Declaration.xml
esemnbun xades XAdES-BES Declaration.txt Embedded.xml --enveloping
```

Вводите PIN только в скрытом запросе или через существующий защищённый ввод с `--pin-stdin`. Приоритет: stdin, `MSIGN_PIN`, запрос. Не помещайте PIN в аргументы, снимки, скрипты или журналы. После ошибки PIN остановитесь и проверьте данные; не повторяйте автоматически.

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf --pin-stdin
```
