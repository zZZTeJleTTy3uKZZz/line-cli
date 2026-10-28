# line-cli

Go-клиент публичного API «Линии» v2 (`https://api.liiniya.ru/v2`) и навык Skillery `line`:
агенты читают и пишут в Telegram, MAX и WhatsApp через подключённые в Линии аккаунты по API-ключу,
без личных сессий `tg`/`max` на каждом устройстве.


## Быстрый старт

```sh
scripts/build.sh                                  # dist/line_<os>_<arch>
line auth login                                   # ссылка и код -> «Разрешить» в кабинете -> ключ сохранён
line auth status
# запасной путь: printf '%s' "$KEY" | line auth set --profile work
line connection list --text
line chat list --query "клиент" --text
line message list <key> <chat_id> --limit 30 --text
line message send <key> <chat_id> --text "Привет" --wait 3m --human
```

Вывод — JSON; `--text` (`--human` у `message send`) — таблицы. Коды выхода: 0 ок, 1 отказ, 2 аргументы,
3 доступ, 4 не найдено, 5 конфликт, 6 сеть, 7 настройки, 8 код входа истёк. Полный перечень — `skills/line/references/commands.md`.

## Настройки

Ключ: `LINE_API_KEY` → связка ключей ОС → `~/.config/line/<профиль>.key` (0600).
Адрес: `--url` → `LINE_API_URL` → `<профиль>.env` → `https://api.liiniya.ru` (прежний `https://api.line.pragmati.ru` остаётся рабочим алиасом).
Профиль: `--profile` → `LINE_PROFILE` → `line auth use` → единственный найденный.
Ключ нигде не печатается и не попадает в репозиторий.

## Разработка

```sh
go vet ./... && go test -race ./... && golangci-lint run ./...
scripts/build.sh 0.1.0          # linux/amd64, windows/amd64, darwin/arm64 (TARGETS=... — другие)
```

Тесты идут против `httptest`-сервера; живой ключ в тестах и фикстурах не используется.
Если `/tmp` смонтирован без exec, задайте `GOTMPDIR` внутри проекта (`_scratchpad/`).

## Навык

`skills/line/` — `SKILL.md`, `_skill_meta.toml`, `install/`, `references/`.
Локальная установка: `skillery install line --path skills/line --force`.
Выпуск: тег `vX.Y.Z` на `main` (CI `go-release`), затем публикация навыка по канону `superskill-canon`.
