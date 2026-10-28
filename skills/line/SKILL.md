---
name: line
description: "CLI `line` — агент читает и пишет в Telegram, MAX и WhatsApp через «Линию» (омниканальный шлюз) по API-ключу, без личных сессий tg/max на каждом устройстве: список диалогов, лента беседы, отправка текста и файлов, скачивание вложений, поиск человека по номеру или имени, подключение нового аккаунта (публичная ссылка входа для владельца). НЕ для постов в каналы, сторис, BotFather, реакций и админки каналов — это telegram-fleet (`tg`). EN triggers: line cli, read telegram chat, send telegram message, send max message, whatsapp message, list dialogs, chat history, read client chat, download attachment, find contact by phone, connect telegram account, login link for owner, omnichannel gateway, line api key. RU триггеры: прочитай чат, прочитай переписку, напиши в телеграм, отправь сообщение в макс, отправь в ватсап, список диалогов, история беседы, чат клиента, скачай вложение, найди контакт по номеру, подключи аккаунт телеграм, ссылка для входа, линия, API Линии, ключ Линии, написать человеку."
metadata:
  openclaw: line
---

Respond in the user's language.

# line — мессенджеры через «Линию»

`line` — Go-клиент публичного API «Линии» v2 (`https://api.line.pragmati.ru/v2`).
Один централизованный аккаунт в Линии держит сессии Telegram, MAX и WhatsApp;
агент ходит туда по API-ключу и не логинится в мессенджеры сам.
Вывод — JSON по умолчанию (`--text` / `--human` — таблицы для человека).

## When activated

- Прочитать диалог или ленту беседы (в том числе клиентский чат или группу).
- Написать человеку или в чат в Telegram, MAX, WhatsApp; приложить файл.
- Посмотреть список диалогов и подключённых аккаунтов, найти человека по номеру или имени.
- Скачать вложение из переписки.
- Подключить новый аккаунт мессенджера: получить публичную ссылку входа, которую откроет владелец аккаунта.

**Не использовать** (остаётся в `telegram-fleet` / `tg`): посты и правка постов в каналах,
сторис, опросы, реакции, BotFather, статистика канала, участники и бан, экспорт канала,
Takeout. Линия этого не делает. Если нужен вход в MAX-сессии для web — `max-cli`.

## Route by request type

| Запрос | Куда |
|--------|------|
| Первая настройка, ключ, профили | Setup ниже, `references/setup.md` |
| Прочитать чат / написать | Instructions, примеры |
| Подключить аккаунт | Instructions §7, `references/connect-account.md` |
| Проверить подключение, лимиты | Instructions §1 |
| Все команды и флаги | `references/commands.md` |
| Что-то не работает | Troubleshooting |

## Setup

Онбординг на новом устройстве: **поставить → `line auth login` → готово**.

1. Бинарник `line` в PATH: `line --version`. Нет — поставить установщиком навыка:
   `install/install.sh` (Linux, WSL, macOS) или `install/install.ps1` (Windows PowerShell) — они качают
   бинарник из публичного GitHub Release с проверкой SHA256SUMS;
   подробности — `references/setup.md`.
2. Вход устройства (ключ руками не нужен):

   ```sh
   line auth login            # покажет ссылку и код, откроет браузер
   line auth status           # ключ принят, ключ не печатается
   ```

   Ссылку и код `line auth login` печатает в stderr и ждёт. Руководитель компании (или техспециалист)
   открывает ссылку в кабинете, проверяет имя устройства и права и жмёт «Разрешить».
   Ключ сохраняется сам (связка ключей ОС или `~/.config/line/<профиль>.key`, 0600) и виден в кабинете
   в разделе ключей — там его можно отозвать. Агенту остаётся передать владельцу ссылку и код;
   ключ агент не видит и не печатает.
   Флаги: `--profile`, `--device-name` (по умолчанию имя компьютера, в WSL с пометкой «/ WSL»),
   `--rights read,send,admin` (по умолчанию `read,send`; `admin` нужен для подключения аккаунтов),
   `--no-browser`. Коды выхода: 0 готово, 3 отказано, 8 код истёк (повторить), 6 сеть.
3. Запасной путь, если вход через кабинет недоступен: ключ выдаёт владелец
   (`admin apikey create --client <клиент> --rights read,send`), кладём через stdin:

   ```sh
   printf '%s' "$KEY" | line auth set --profile work --set-url https://api.line.pragmati.ru
   ```

   Ключ ищется так: `LINE_API_KEY` → связка ключей ОС → `~/.config/line/<профиль>.key` (0600).
   Профиль: `--profile` → `LINE_PROFILE` → `line auth use <профиль>` → единственный найденный.
   Адрес: `--url` → `LINE_API_URL` → `<профиль>.env` → `https://api.line.pragmati.ru`.
   Адрес — именно `api.line.pragmati.ru`, а не `app.line...` (это веб-кабинет).

## Instructions

Общий порядок: **проверить подключение → найти диалог → прочитать → (по поручению) написать**.
Везде `<key>` — ключ подключения (поле `key` из `line connection list`, например `tg:12`),
`<chat_id>` — номер диалога из `line chat list`. Добавь `--text`, если нужна таблица для человека.

### 1. Проверить, что всё работает

```sh
line auth status                  # ключ принят, профиль и адрес (ключ не печатается)
line connection list --text       # какие аккаунты подключены; нужен can_send_now: true для отправки
line connection get <key>         # состояние одного подключения и что нужно от человека
line limits                       # пределы частоты запросов этого ключа
```

Подключение не в рабочем состоянии (`state` не рабочий, `can_send_now: false`) — писать нельзя;
если аккаунт вышел: `line connection relogin <key>` и ссылка входа (шаг 7).

### 2. Список диалогов

```sh
line chat list --limit 50 --text                    # последние диалоги по всем подключениям
line chat list --connection <key> --text            # только один аккаунт
line chat list --query "Ромашка" --text                 # по имени, номеру, метке, последнему сообщению
line chat list --limit 50 --cursor <next_cursor>    # следующая страница
```

### 3. Найти человека, группу или канал

```sh
line contact find "+7 900 000-00-00"   # по номеру: карточка контакта
line contact find "Иван"               # по имени: диалоги с таким именем
line search "договор" --text           # по имени, метке и последнему сообщению диалогов
line search "договор" --messages       # ещё и по последним сообщениям первых диалогов
line chat get <key> <chat_id>          # строка диалога и профиль собеседника
```

Группы и каналы лежат в том же `chat list`; отличай по имени и полям ответа. Поиска по всей
истории у службы нет: глубже ищи, читая ленту (`message list --before`).
Нужно знать, есть ли номер в мессенджере: `line contact check <номер> --connection <key>`.

### 4. Прочитать переписку

```sh
line message list <key> <chat_id> --limit 50 --text           # от старых к новым
line message list <key> <chat_id> --before 2026-10-23T00:00:00Z   # старше момента
```

Чтение ничего не отмечает прочитанным. Группа — это обычный `chat_id` (у групп Telegram он
отрицательный, пиши как есть или после `--`). Параметра темы форума в API v2 нет: лента группы
отдаёт сообщения всех тем вместе, различай их по полям сообщения в JSON.

### 5. Отправить текст или файл

```sh
line message send <key> <chat_id> --text "Привет" --wait 3m --human
line message send <key> <chat_id> --text-file ./reply.txt --file ./smeta.pdf --wait 3m --human
line message send <key> --phone +79991112233 --text "Здравствуйте" --known-only
line message status <id>            # судьба отправки по id из ответа send
```

Ответ `send` — `id` в очереди, а не доставка. Сообщения ключа идут через **темп подключения**
(минуты между отправками, статус `queued`): не повторяй отправку руками, смотри `message status`.
`--known-only` пишет на номер только в уже существующий диалог. Новому номеру сначала `contact check`.

### 5а. Чужой бот от личного MAX: «Старт» с меткой и кнопки

```sh
line bot start <key> --bot <имя_бота|номер> --payload <метка>   # как max.ru/<бот>?start=<метка>; ответ: chat_id
line message list <key> <chat_id> --text                         # ответ бота; у кнопок видны место ряд:кнопка и команда нажатия
line message press <key> <chat_id> <external_id> --payload <код> # нажать по коду (keyboard.rows[][].data)
line message press <key> <chat_id> <external_id> --button 0:1    # или по месту (ряд:кнопка с нуля)
```

Бот получает настоящие `bot_started` (с меткой) и `message_callback`. Текстом «/start метка» это не
делается. Нажимаются кнопки вида `CALLBACK` (поле `type` в `keyboard` ленты); ссылка (`LINK`) и запрос
контакта дают `button_not_pressable`. Только личный MAX (`max:…`), нужен ключ с правом `send`; другие
роды подключений отвечают 501.

### 6. Скачать вложение

```sh
line media download <attachment_id> -o ./smeta.pdf      # id из attachment.id в ленте
line media download <attachment_id> --url-only          # только временный адрес
# вложение без attachment.id (лежит у мессенджера): по адресу сообщения; --text в ленте подсказывает команду
line media download --message <key> <chat_id> <external_id> -o ./file   # альбом: добавь -n 1, -n 2…
line media download <attachment.download из ленты> -o ./file            # то же, по готовому пути
line media upload ./photo.jpg                           # положить файл, получить attachment_id
```

### 7. Подключить новый аккаунт (ссылка входа)

Агент аккаунт сам не авторизует: вход подтверждает владелец аккаунта. Для этого нужны права
`admin` (`line auth login --rights read,send,admin`).

```sh
line connection add telegram --title "Личный Telegram"   # или max / whatsapp, при входе кодом --phone +7...
line connection get <key> --text                         # дождаться рабочего состояния
```

Из ответа `add` возьми `login_link.url` и **передай владельцу аккаунта** (ссылка живёт ~30 минут).
Подробнее и про код/пароль — `references/connect-account.md`.

### Особенности ключа API

- `message send --text` занят телом сообщения, поэтому человекочитаемый вывод у send включается `--human`.
- Поиска по тексту у службы нет: `search` и `chat list --query` отбирают на клиенте.
- Права ключа ограничены тем, что подтвердил владелец при `line auth login`; чужие клиенты недоступны.

## Examples

### Example 1 — типовой случай: прочитать и ответить

```sh
# что подключено и что можно писать
line connection list --text

# найти клиентский чат и прочитать последние сообщения
line chat list --query "Ромашка" --text
line message list tg:12 -1001234567890 --limit 40 --text

# ответить с файлом и дождаться итога
line message send tg:12 -1001234567890 --text "Смета во вложении" --file ./smeta.pdf --wait 3m --human

```

### Example 2 — пограничные случаи: вложение, номер без диалога, новый аккаунт

```sh
# скачать вложение из ленты
line media download <attachment_id> -o ./smeta.pdf

# найти человека по номеру
line contact find "+7 900 000-00-00"

# подключить новый аккаунт MAX: ссылку получает владелец
line connection add max --title "Личный MAX"
```

## Rules

- Ключ API никогда не печатать, не класть в команды, беседу, задачи, репозитории, логи.
  Только `line auth login` (ключ сохраняется сам), `line auth set` через stdin или `LINE_API_KEY` в окружении процесса.
- Пароль облачного Telegram, коды входа и ссылки входа — владельцу, а не в чаты и задачи.
  Агент сам аккаунт не авторизует.
- Не отправляй сообщения людям без прямого поручения владельца; перед массовой рассылкой
  покажи текст и список адресатов.
- Деструктивное (`connection signout`) только с явного подтверждения владельца.
- Коды выхода: 0 ок, 1 отказ службы, 2 аргументы, 3 доступ (401/403), 4 не найдено,
  5 конфликт, 6 сеть, 7 настройки/нет ключа, 8 код входа истёк. Ошибки — JSON в stderr с `request_id`:
  его называй при обращении к поддержке.

## Troubleshooting

- `7`, «ключ не найден» — не выполнен `line auth login` (или `auth set`) для этого профиля; проверь `line auth profiles`.
- `line auth login`: `3` — владелец нажал «Отказать» или у него нет права разрешать; `8` — код истёк за 10 минут, запусти вход заново.
- `3` / 401 — ключ отозван или не тот профиль/адрес; `line auth status`.
- 403 `permission` — у ключа нет права (`send`, `admin`); попроси владельца выдать.
- `chat list` пуст при `connections: []` — аккаунт ещё не подключён: `references/connect-account.md`.
- Пустая лента у нового подключения — история подтягивается не сразу; для бота MAX люди
  заводятся через `line chat import`.
- 422 `recipient_unknown` — диалога с номером нет: сделай `contact check`, затем send без `--known-only`.
- Сеть (6), 429/5xx — клиент сам повторяет запросы; при постоянном сбое проверь адрес (`--url`).
