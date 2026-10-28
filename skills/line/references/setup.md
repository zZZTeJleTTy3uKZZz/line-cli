# Установка и настройка line

## Бинарник

| Платформа | Файл релиза |
|-----------|-------------|
| Linux x86-64 | `line_linux_amd64.tar.gz` |
| Linux ARM64 | `line_linux_arm64.tar.gz` |
| macOS Apple Silicon | `line_darwin_arm64.tar.gz` |
| macOS Intel | `line_darwin_amd64.tar.gz` |
| Windows x86-64 | `line_windows_amd64.zip` |

Установщики `install/install.sh` (Linux, WSL, macOS) и `install/install.ps1` (Windows PowerShell)
качают архив из публичного GitHub Release
`https://github.com/zZZTeJleTTy3uKZZz/line-cli/releases/download/v<версия>/line_<os>_<arch>.tar.gz`
(`.zip` для Windows) без токенов. Версия = версии навыка (`_skill_meta.toml`) или `LINE_CLI_VERSION`;
контрольная сумма из `SHA256SUMS` проверяется всегда.

Переопределения: `LINE_CLI_BASE_URL` — каталог/URL с теми же файлами (в т.ч. `file:///...`),
`LINE_CLI_SRC` — путь к исходникам для сборки `go build`.

Выпуски собирает CI на тег `vX.Y.Z`: linux amd64/arm64, windows amd64, darwin amd64/arm64 и `SHA256SUMS`.

Куда ставится: `$PREFIX` (по умолчанию `~/.local/bin`, на Windows
`%USERPROFILE%\.local\bin`; каталог добавляется в PATH пользователя).

## Вход устройства

```sh
line auth login                                   # профиль = имя клиента из ответа
line auth login --profile work --device-name "ноутбук" --rights read,send,admin
```

Команда создаёт запрос входа (`POST /v2/device-auth`, без ключа), печатает ссылку и код
подтверждения в stderr и пытается открыть браузер (`xdg-open`, `open`, `rundll32 url.dll`,
`wslview`; нет браузера — не ошибка). Дальше она опрашивает службу с её интервалом и
замедляется по `slow_down`. Руководитель компании (или техспециалист) открывает ссылку в кабинете,
видит имя устройства и права и жмёт «Разрешить» или «Отказать». Ключ приходит один раз и сразу
сохраняется; в вывод и логи не попадает. Устройство видно в кабинете (раздел ключей) как
«устройство: <имя>» и отзывается там же.

Коды выхода: 0 готово, 3 отказано, 8 код истёк (10 минут), 6 сеть, 1 прервано (Ctrl+C).
Имя устройства по умолчанию — имя компьютера, в WSL с пометкой « / WSL».

## Ключ вручную и профили

```sh
printf '%s' "$KEY" | line auth set --profile work --set-url https://api.liiniya.ru
line auth use work            # профиль по умолчанию
line auth profiles               # список
line auth status                 # проверка ключа запросом GET /connections
line auth remove --profile work
```

Хранилище: связка ключей ОС (Secret Service / Keychain / Credential Manager);
если её нет (контейнер, WSL без D-Bus) — файл `~/.config/line/<профиль>.key` с правами 0600.
`LINE_KEYRING=off` отключает связку. Каталог настроек — `LINE_CONFIG_DIR`.

Переменные окружения: `LINE_API_KEY`, `LINE_API_URL`, `LINE_PROFILE`.
Адрес API — `https://api.liiniya.ru` (версию `/v2` клиент добавит сам). Прежний `https://api.line.pragmati.ru` работает как алиас без срока.
`app.liiniya.ru` — это веб-кабинет, в API не годится.
