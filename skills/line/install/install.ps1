# Установка бинарника line (Windows PowerShell 5.1+ / 7) из публичного GitHub Release - без токенов.
#   Источник: https://github.com/zZZTeJleTTy3uKZZz/line-cli/releases/download/v<версия>/line_windows_amd64.zip
#   Версия = версии навыка (_skill_meta.toml рядом) или LINE_CLI_VERSION. Контрольная сумма из
#   SHA256SUMS проверяется всегда.
# Переопределения: LINE_CLI_BASE_URL (каталог/URL с теми же файлами), LINE_CLI_SRC (исходники, go build),
#   PREFIX (по умолчанию $HOME\.local\bin; каталог добавляется в PATH пользователя).
# Ключ API установщик не трогает: после установки - line auth login.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repo = if ($env:LINE_CLI_GITHUB_REPO) { $env:LINE_CLI_GITHUB_REPO } else { 'zZZTeJleTTy3uKZZz/line-cli' }
$prefix = if ($env:PREFIX) { $env:PREFIX } else { Join-Path $HOME '.local\bin' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$ver = $env:LINE_CLI_VERSION
if (-not $ver) {
  $meta = Join-Path $here '..\_skill_meta.toml'
  if (Test-Path $meta) {
    $m = Select-String -Path $meta -Pattern '^version\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($m) { $ver = $m.Matches[0].Groups[1].Value }
  }
}
if ($ver) { $ver = $ver.TrimStart('v') }
$archive = 'line_windows_amd64.zip'

# Windows PowerShell 5.1 по умолчанию без TLS 1.2 - GitHub иначе не откроется.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

New-Item -ItemType Directory -Force -Path $prefix | Out-Null
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("line-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  $exe = Join-Path $tmp 'line.exe'
  if ($env:LINE_CLI_SRC -and -not $env:LINE_CLI_BASE_URL) {
    Push-Location $env:LINE_CLI_SRC
    try { $env:CGO_ENABLED = '0'; go build -trimpath -ldflags '-s -w' -o $exe ./cmd/line } finally { Pop-Location }
  } else {
    if (-not $env:LINE_CLI_BASE_URL -and -not $ver) { throw 'Версия не определена: задайте LINE_CLI_VERSION' }
    $base = if ($env:LINE_CLI_BASE_URL) { $env:LINE_CLI_BASE_URL } else { "https://github.com/$repo/releases/download/v$ver" }
    $base = $base.TrimEnd('/')
    $sums = Join-Path $tmp 'SHA256SUMS'
    $zip = Join-Path $tmp $archive
    Invoke-WebRequest "$base/SHA256SUMS" -OutFile $sums -UseBasicParsing
    Invoke-WebRequest "$base/$archive" -OutFile $zip -UseBasicParsing
    $line = Get-Content $sums | Where-Object { $_.Trim() -and (($_ -split '\s+', 2)[1].TrimStart('*') -eq $archive) } | Select-Object -First 1
    if (-not $line) { throw "В SHA256SUMS нет $archive" }
    $want = ($line -split '\s+')[0].ToLower()
    $got = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($got -ne $want) { throw "Контрольная сумма $archive не совпала" }
    $dir = Join-Path $tmp 'x'
    Expand-Archive -Path $zip -DestinationPath $dir -Force
    $bin = Get-ChildItem -Path $dir -Recurse -Filter 'line.exe' | Select-Object -First 1
    if (-not $bin) { throw "В архиве $archive нет line.exe" }
    Copy-Item $bin.FullName $exe -Force
  }
  Copy-Item $exe (Join-Path $prefix 'line.exe') -Force
  Write-Host "line установлен: $prefix\line.exe"
  & (Join-Path $prefix 'line.exe') --version
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (($userPath -split ';') -notcontains $prefix) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$prefix", 'User')
    Write-Host 'Каталог добавлен в PATH пользователя; откройте новый терминал'
  }
  # Шим Skillery (~/.skillery/bin/line.cmd) на Windows не раскрывает ~ в пути: направим его на установленный line.exe.
  $shim = Join-Path $HOME '.skillery\bin\line.cmd'
  if (Test-Path $shim) {
    Set-Content -Path $shim -Value ("@echo off`r`n`"" + (Join-Path $prefix 'line.exe') + "`" %*`r`nexit /b %errorlevel%`r`n") -Encoding Ascii
  }
  Write-Host 'Дальше: line auth login   (ссылка и код подтверждаются в кабинете; ключ сохранится сам)'
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
