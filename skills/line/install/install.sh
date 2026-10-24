#!/usr/bin/env bash
# Установка бинарника line (Linux, WSL, macOS) из публичного GitHub Release — без токенов.
#   Источник: https://github.com/zZZTeJleTTy3uKZZz/line-cli/releases/download/v<версия>/line_<os>_<arch>.tar.gz
#   Версия = версии навыка (_skill_meta.toml рядом) или LINE_CLI_VERSION. Контрольная сумма из
#   SHA256SUMS проверяется всегда.
# Переопределения: LINE_CLI_BASE_URL (каталог/URL с теми же файлами, в т.ч. file:///...),
#   LINE_CLI_SRC (исходники: сборка `go build`), PREFIX (по умолчанию ~/.local/bin).
# Ключ API установщик не трогает: после установки — `line auth login`.
set -euo pipefail

REPO="${LINE_CLI_GITHUB_REPO:-zZZTeJleTTy3uKZZz/line-cli}"
PREFIX="${PREFIX:-$HOME/.local/bin}"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) echo "line: неподдерживаемая ОС $(uname -s); для Windows — install.ps1" >&2; exit 2 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "line: неподдерживаемая архитектура $(uname -m)" >&2; exit 2 ;;
esac

ver="${LINE_CLI_VERSION:-}"
if [ -z "$ver" ] && [ -f "$here/../_skill_meta.toml" ]; then
  ver="$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$here/../_skill_meta.toml" | head -n1)"
fi
ver="${ver#v}"
archive="line_${os}_${arch}.tar.gz"

mkdir -p "$PREFIX"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

if [ -n "${LINE_CLI_SRC:-}" ] && [ -z "${LINE_CLI_BASE_URL:-}" ]; then
  (cd "$LINE_CLI_SRC" && CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o "$tmp/line" ./cmd/line)
else
  [ -n "${LINE_CLI_BASE_URL:-}" ] || [ -n "$ver" ] || { echo "line: версия не определена: задайте LINE_CLI_VERSION" >&2; exit 2; }
  base="${LINE_CLI_BASE_URL:-https://github.com/$REPO/releases/download/v$ver}"
  base="${base%/}"
  curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"
  curl -fsSL "$base/$archive" -o "$tmp/$archive"
  want="$(awk -v a="$archive" '$2==a || $2=="*"a {print $1}' "$tmp/SHA256SUMS")"
  [ -n "$want" ] || { echo "line: в SHA256SUMS нет $archive" >&2; exit 3; }
  [ "$(sha256 "$tmp/$archive")" = "$want" ] || { echo "line: контрольная сумма $archive не совпала" >&2; exit 3; }
  mkdir -p "$tmp/x"
  tar -xzf "$tmp/$archive" -C "$tmp/x"
  [ -f "$tmp/x/line" ] || { echo "line: в архиве $archive нет бинарника line" >&2; exit 3; }
  cp "$tmp/x/line" "$tmp/line"
fi

install -m 0755 "$tmp/line" "$PREFIX/line"
echo "line установлен: $PREFIX/line"
"$PREFIX/line" --version
case ":$PATH:" in *":$PREFIX:"*) ;; *) echo "Добавьте $PREFIX в PATH (например, в ~/.profile) и откройте новый терминал" ;; esac
echo "Дальше: line auth login   (ссылка и код подтверждаются в кабинете; ключ сохранится сам)"
