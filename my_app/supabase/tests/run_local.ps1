param(
  [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin',
  [int]$Port = 55439,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = [System.IO.Path]::GetFullPath(
  (Join-Path $PSScriptRoot '..\..')
)
$tempRoot = Join-Path $projectRoot '.tmp'
$cluster = Join-Path $tempRoot "pg_questreal_$PID"
$log = Join-Path $tempRoot "pg_questreal_$PID.log"
$sqlOutput = Join-Path $tempRoot "pg_questreal_$PID.sql.log"
$database = 'questreal_test'
$started = $false

function Assert-ExitCode([string]$Step) {
  if ($LASTEXITCODE -ne 0) {
    throw "$Step failed with exit code $LASTEXITCODE."
  }
}

function Invoke-SqlFile([string]$File, [string]$Step) {
  $arguments = @(
    '-q',
    '-h', '127.0.0.1',
    '-p', $Port,
    '-U', 'postgres',
    '-d', $database,
    '-v', 'ON_ERROR_STOP=1'
  )
  if ($Quiet) {
    $arguments += @('-o', $sqlOutput)
  }
  $arguments += @('-f', $File)

  & (Join-Path $PgBin 'psql.exe') @arguments
  Assert-ExitCode $Step
}

foreach ($executable in @('initdb.exe', 'pg_ctl.exe', 'createdb.exe', 'psql.exe')) {
  $path = Join-Path $PgBin $executable
  if (-not (Test-Path -LiteralPath $path)) {
    throw "PostgreSQL executable not found: $path"
  }
}

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
if (Test-Path -LiteralPath $cluster) {
  throw "Temporary cluster already exists: $cluster"
}

Push-Location $projectRoot
try {
  & (Join-Path $PgBin 'initdb.exe') `
    -D $cluster -A trust -U postgres --encoding=UTF8 --no-locale
  Assert-ExitCode 'initdb'

  # Không pipe pg_ctl qua Out-Null: trên Windows tiến trình postgres con có thể
  # giữ output handle và khiến terminal tưởng lệnh vẫn chưa kết thúc.
  & (Join-Path $PgBin 'pg_ctl.exe') `
    -D $cluster -l $log -o "-p $Port" -w start
  Assert-ExitCode 'pg_ctl start'
  $started = $true

  & (Join-Path $PgBin 'createdb.exe') `
    -h 127.0.0.1 -p $Port -U postgres $database
  Assert-ExitCode 'createdb'

  Invoke-SqlFile 'supabase/tests/bootstrap.sql' 'bootstrap.sql'

  Get-ChildItem 'supabase/migrations' -Filter '*.sql' |
    Sort-Object Name |
    ForEach-Object {
      Write-Host "Applying $($_.Name)"
      Invoke-SqlFile $_.FullName $_.Name
    }

  Invoke-SqlFile 'supabase/tests/integration.sql' 'integration.sql'
  Invoke-SqlFile 'supabase/preflight.sql' 'preflight.sql'

  Write-Host 'QuestReal local database verification passed.' -ForegroundColor Green
}
finally {
  Pop-Location

  if ($started -and (Test-Path -LiteralPath (Join-Path $cluster 'postmaster.pid'))) {
    & (Join-Path $PgBin 'pg_ctl.exe') -D $cluster -m fast -w stop
  }

  $safeRoot = [System.IO.Path]::GetFullPath($tempRoot).TrimEnd('\') + '\'
  $resolvedCluster = [System.IO.Path]::GetFullPath($cluster)
  if (-not $resolvedCluster.StartsWith(
      $safeRoot,
      [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Unsafe cleanup target: $resolvedCluster"
  }

  if (Test-Path -LiteralPath $cluster) {
    Remove-Item -LiteralPath $cluster -Recurse -Force
  }
  if (Test-Path -LiteralPath $log) {
    Remove-Item -LiteralPath $log -Force
  }
  if (Test-Path -LiteralPath $sqlOutput) {
    Remove-Item -LiteralPath $sqlOutput -Force
  }
}
