# Подключение нового аккаунта мессенджера

Агент не авторизует аккаунт сам: вход подтверждает владелец аккаунта (код из SMS/приложения,
QR, облачный пароль). Агент создаёт запись входа и отдаёт владельцу публичную ссылку.

```sh
# QR: владелец сканирует QR на странице по ссылке
line connection add telegram --title "Личный Telegram"

# вход кодом на номер: код придёт владельцу, вводит он на странице по ссылке
line connection add max --phone +79000000000
```

Ответ содержит `connection.key` и `login_link.url` (живёт ~30 минут, гаснет после входа).
Передай `url` владельцу. Дальше:

```sh
line connection get <key> --text      # состояние и что нужно от человека
line connection poll <key>            # продвинуть вход (спросить мессенджер)
```

Если владелец отдаёт код/пароль агенту, а не вводит на странице:

```sh
line connection code <key> 12345
printf '%s' "$CLOUD_PASSWORD" | line connection password <key>   # пароль только через stdin
```

Аккаунт вышел и нужен тот же ключ и переписка: `line connection relogin <key> [--phone ...]`,
затем `line connection login-link <key>`.

Одноразовый пропуск окна QR (для встроенного окна кабинета): `line connection login-link <key> --ticket`.

Когда `state` станет рабочим и `can_send_now: true`, аккаунт готов:
`line chat list --connection <key>`.

Бот MAX: люди, нажавшие «Старт» до подключения бота к Линии, заводятся
`line chat import <key> --file chats.json` (массив `{chat_id,name,phone,user_id}`).
