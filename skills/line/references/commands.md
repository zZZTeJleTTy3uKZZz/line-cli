# Команды line

Глобальные флаги: `--profile/-P`, `--url`, `--text` (или `--human`), `--timeout 30s`, `--retries 3`.
Вывод JSON; ошибки JSON в stderr; коды выхода: 0, 1 отказ, 2 аргументы, 3 доступ, 4 не найдено,
5 конфликт, 6 сеть, 7 настройки.

| Команда | Ручка API | Что делает |
|---------|-----------|------------|
| `auth login [--device-name N] [--rights read,send,admin] [--client-hint C] [--no-browser]` | POST /device-auth, /device-auth/poll | вход устройства: ссылка и код в stderr, ключ сохраняется сам; коды 3 отказ, 8 истёк |
| `auth set [--file] [--set-url U]` | — | ключ из stdin в связку ОС / файл 0600 |
| `auth status` | GET /connections | профиль, адрес, источник ключа, принят ли |
| `auth profiles` / `use <p>` / `remove` | — | профили на машине |
| `connection list [--deleted]` | GET /connections | подключения: состояние, can_send_now |
| `connection get <key>` | GET /connections/{key} | состояние и шаг входа |
| `connection add <telegram\|max\|whatsapp> [--phone] [--title] [--way] [--ttl] [--no-link]` | POST /connections + /login/share-links | завести вход, выдать ссылку |
| `connection login-link <key> [--ttl] [--ticket]` | POST /connections/{key}/login/share-links (+window-tickets) | публичная ссылка входа |
| `connection poll <key>` / `code <key> <код>` / `password <key>` | POST .../login/{poll,code,password} | шаги входа |
| `connection relogin <key> [--phone]` | POST /connections/{key}/login | войти снова в ту же запись |
| `connection reconnect <key>` | POST .../reconnect | поднять канал из сессии |
| `connection signout <key> --yes` | POST .../signout | выйти из аккаунта |
| `chat list [--connection] [--query] [--phone] [--responsible] [--sort] [--limit] [--cursor] [--scan]` | GET /chats | диалоги; `--query` на клиенте |
| `chat get <key> <chat_id>` | GET /chats/{chat_id}/peer + список | диалог и профиль собеседника |
| `chat import <key> (--file F \| --chat-id ...)` | POST /connections/{key}/chats/import | завести известные чаты бота |
| `message list <key> <chat_id> [--limit] [--before]` | GET /chats/{key}/{chat_id}/messages | лента |
| `message send <key> [chat_id] [--text\|--text-file] [--file]... [--phone] [--known-only] [--reply-to] [--wait D]` | POST /messages (+POST /media) | отправить |
| `message status <id>` | GET /messages/{id} | судьба отправки |
| `bot start <key> --bot <имя\|номер> [--payload <метка>]` | POST /chats/{key}/bot-starts | «Старт» чужого бота от личного MAX: бот получает bot_started с меткой; в ответе chat_id |
| `message press <key> <chat_id> <external_id> --payload <код>\|--button <ряд:кнопка>` | POST /chats/{key}/{chat_id}/messages/{external_id}/presses | нажать кнопку CALLBACK под сообщением бота (место с нуля) |
| `media upload <файл>` | POST /media | положить файл, получить attachment_id |
| `media download <id> -o файл [--force] [--url-only]` | GET /media/{id} | скачать вложение со склада Линии |
| `media download --message <key> <chat_id> <external_id> [-n N] -o файл` | GET /chats/{key}/{chat_id}/messages/{external_id}/attachment | скачать вложение сообщения, в том числе лежащее у мессенджера (нет attachment.id); `-n` — номер в альбоме с нуля |
| `media download <url> -o файл` | GET по `attachment.download` | то же по адресу из ленты |
| `contact find <номер\|имя>` | GET /contacts?phone= / список диалогов | найти человека |
| `contact get <id>` / `check <номер> --connection K` | GET /contacts/{id} / POST /contacts/check | карточка / есть ли номер в мессенджере |
| `search <текст> [--messages] [--connection]` | GET /chats (+ленты) | поиск на клиенте |
| `limits` | GET /limits | пределы частоты ключа |

Повторы: GET/DELETE/PUT — на 429/5xx и сбоях сети с паузой и `Retry-After`; POST — на 429,
а на 5xx/сеть только с `Idempotency-Key` (send, add, upload ставят его сами).
