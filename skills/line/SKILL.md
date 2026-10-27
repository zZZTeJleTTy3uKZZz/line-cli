---
name: line
description: "Единый канал мессенджеров Telegram, MAX, WhatsApp: CLI line по API-ключу. Прочитать чат/ленту, список диалогов, написать человеку или в группу, файл, вложение, найти контакт, подключить аккаунт. EN: read/send telegram, max, whatsapp message, chat history. RU: прочитай чат, напиши в телеграм/макс/ватсап."
---

Respond in the user's language.

# line — все мессенджеры через «Линию»

`line` — Go-клиент API «Линии» v2. Один аккаунт Линии держит сессии Telegram, MAX, WhatsApp;
агент ходит по API-ключу и сам в мессенджеры не логинится. Вывод JSON, `--text` — таблицы.

## Когда использовать

- Прочитать диалог, ленту, клиентский чат или группу; список диалогов; поиск человека.
- Написать в Telegram, MAX, WhatsApp (текст, файл); скачать вложение.
- Подключить новый аккаунт (ссылка входа для владельца аккаунта).

Узко, не в `line` (навык `telegram`, CLI `tg`): посты в каналах, сторис, опросы, реакции,
BotFather, статистика, участники и бан, экспорт/Takeout. Вход в web-сессию MAX — `max-cli`.

## Проверка и вход

```sh
line --version                    # нет в PATH: bash install/install.sh (или /opt/tools/bin/line)
line auth login                   # устройство: ссылка и код в stderr, владелец жмёт «Разрешить»
line auth status                  # ключ принят (ключ не печатается)
line connection list --text       # какие аккаунты; для отправки нужен can_send_now: true
```

`--rights read,send,admin` — admin нужен для подключения аккаунтов. Профиль: `--profile`,
`LINE_PROFILE`, `line auth use`. Адрес API — `api.line.pragmati.ru` (не `app.line…`).

## Главные команды

Порядок: проверить подключение → найти диалог → прочитать → (по поручению) написать.
`<key>` — поле `key` из `connection list` (например `tg:12`), `<chat_id>` из `chat list`.

```sh
line chat list --limit 50 --text                  # диалоги; --connection <key>, --query "имя"
line contact find "+7 900 000-00-00"              # человек по номеру или имени
line search "договор" --messages --text           # поиск по диалогам и ленте
line message list <key> <chat_id> --limit 50 --text           # лента, старые → новые
line message send <key> <chat_id> --text "Привет" --file ./a.pdf --wait 3m --human
line message status <id>                          # судьба отправки
line media download <attachment_id> -o ./file     # вложение из ленты
line connection add telegram --title "Личный"     # новый аккаунт: login_link.url отдать владельцу
```

Ответ `send` — id в очереди, не доставка: сообщения идут с темпом подключения, не повторяй
руками, смотри `message status`. `--known-only` пишет на номер только в существующий диалог;
новый номер сначала `line contact check <номер> --connection <key>`.
Чтение ничего не отмечает прочитанным. Лента группы отдаёт все темы форума вместе.

## Правила

- Ключ API не печатать и не класть в команды, чаты, задачи, репозитории; только `auth login`,
  `auth set` через stdin или `LINE_API_KEY` в окружении процесса.
- Пароль Telegram, коды и ссылки входа — владельцу, не в чаты и задачи. Агент аккаунт не авторизует.
- Не писать людям без прямого поручения; перед рассылкой показать текст и адресатов.
- `connection signout` — только с явного подтверждения.
- Коды выхода: 0 ок, 1 отказ, 2 аргументы, 3 доступ, 4 не найдено, 5 конфликт, 6 сеть,
  7 нет ключа/настройки, 8 код входа истёк. Ошибка — JSON в stderr с `request_id`.

## Типичные сбои

- 7 «ключ не найден» — нет `line auth login` для профиля (`line auth profiles`).
- 3 / 401 — ключ отозван или не тот профиль/адрес; 403 — не хватает права (`send`, `admin`).
- `chat list` пуст при `connections: []` — аккаунт не подключён (`references/connect-account.md`).
- 422 `recipient_unknown` — диалога нет: `contact check`, затем send без `--known-only`.

## Справочники (`references/`)

`commands.md` (все команды и флаги) · `setup.md` (установка, ключи, профили) ·
`connect-account.md` (подключение аккаунта) · `full-legacy.md` (прежний подробный текст с примерами).
