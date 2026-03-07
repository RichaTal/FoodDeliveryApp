# =============================================================
#  Local Development Setup - restaurant_db
#  Creates the restaurant_db database and seeds it with data.
#
#  Works in two modes (auto-detected):
#    1. LOCAL psql  - if psql is on PATH, connects directly
#    2. DOCKER psql - uses the running postgres Docker container
#
#  Prerequisites (one of):
#    - PostgreSQL installed with psql on PATH, OR
#    - Docker running with the project postgres container up
#
#  Usage:
#    .\scripts\setup-local-restaurant-db.ps1
#    .\scripts\setup-local-restaurant-db.ps1 -ServiceName restaurant-menu-service
#
#  Optional overrides:
#    .\scripts\setup-local-restaurant-db.ps1 -PgHost localhost -PgPort 5432 -PgUser postgres -PgPassword postgres123
# =============================================================

param(
    [string]$PgHost          = "",
    [string]$PgPort          = "",
    [string]$PgUser          = "",
    [string]$PgPassword      = "",
    [string]$DockerContainer = "",
    [string]$ServiceName     = "restaurant-menu-service"
)

$ErrorActionPreference = "Stop"

# Resolve script and project root paths
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SqlFile     = Join-Path $ProjectRoot "infra\postgres\init-restaurant.sql"

# Try to find .env file in priority order:
#   1. Service-specific .env (services/{ServiceName}/.env)
#   2. Root .env (project root/.env)
$ServiceEnvFile = Join-Path $ProjectRoot "services\$ServiceName\.env"
$RootEnvFile    = Join-Path $ProjectRoot ".env"

$EnvFile = $null
if (Test-Path $ServiceEnvFile) {
    $EnvFile = $ServiceEnvFile
    Write-Host "Found service .env: $ServiceEnvFile" -ForegroundColor Green
} elseif (Test-Path $RootEnvFile) {
    $EnvFile = $RootEnvFile
    Write-Host "Found root .env: $RootEnvFile" -ForegroundColor Yellow
    Write-Host "  (Service .env not found at: $ServiceEnvFile)" -ForegroundColor Yellow
} else {
    Write-Host "No .env file found - using defaults." -ForegroundColor Yellow
    Write-Host "  Checked: $ServiceEnvFile" -ForegroundColor Gray
    Write-Host "  Checked: $RootEnvFile" -ForegroundColor Gray
}

# Load .env file into a hashtable
$envVars = @{}
if ($EnvFile) {
    foreach ($rawLine in (Get-Content $EnvFile)) {
        $trimmed = $rawLine.Trim()
        if ($trimmed -and (-not $trimmed.StartsWith("#")) -and ($trimmed -match "^([^=]+)=(.*)$")) {
            $envVars[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    Write-Host "Loaded credentials from: $EnvFile" -ForegroundColor Cyan
}

# Resolve connection parameters: script param > .env > built-in default
if ($PgHost -eq "")     { if ($envVars.ContainsKey("POSTGRES_HOST"))     { $PgHost     = $envVars["POSTGRES_HOST"] }     else { $PgHost     = "localhost" } }
if ($PgPort -eq "")     { if ($envVars.ContainsKey("POSTGRES_PORT"))     { $PgPort     = $envVars["POSTGRES_PORT"] }     else { $PgPort     = "5432" } }
if ($PgUser -eq "")     { if ($envVars.ContainsKey("POSTGRES_USER"))     { $PgUser     = $envVars["POSTGRES_USER"] }     else { $PgUser     = "postgres" } }
if ($PgPassword -eq "") { if ($envVars.ContainsKey("POSTGRES_PASSWORD")) { $PgPassword = $envVars["POSTGRES_PASSWORD"] } else { $PgPassword = "postgres123" } }

$TargetDb = "restaurant_db"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Local restaurant_db Setup"                  -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Host     : $PgHost"
Write-Host "  Port     : $PgPort"
Write-Host "  User     : $PgUser"
Write-Host "  Database : $TargetDb"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Detect execution mode: local psql or Docker
# ------------------------------------------------------------------
$UseDocker = $false
$PsqlPath  = $null

if (Get-Command psql -ErrorAction SilentlyContinue) {
    $PsqlPath = "psql"
    Write-Host "Mode: Local psql detected." -ForegroundColor Green
} elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Mode: psql not found locally - checking Docker..." -ForegroundColor Yellow

    # Find the postgres container name (support -DockerContainer override)
    if ($DockerContainer -eq "") {
        $containers = & docker ps --format "{{.Names}}" 2>&1
        foreach ($c in ($containers | Out-String).Split("`n")) {
            $c = $c.Trim()
            if ($c -match "postgres") {
                $DockerContainer = $c
                break
            }
        }
    }

    if ($DockerContainer -eq "") {
        Write-Host "ERROR: No running postgres Docker container found." -ForegroundColor Red
        Write-Host "  Start the stack first:  docker compose up -d postgres" -ForegroundColor Yellow
        Write-Host "  Or install PostgreSQL:  https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
        exit 1
    }

    $UseDocker = $true
    Write-Host "  Using Docker container: $DockerContainer" -ForegroundColor Green
} else {
    Write-Host "ERROR: Neither 'psql' nor 'docker' found on PATH." -ForegroundColor Red
    Write-Host "  Option 1 - Install PostgreSQL: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    Write-Host "  Option 2 - Install Docker Desktop and start the stack." -ForegroundColor Yellow
    exit 1
}

# Verify the SQL init file exists
if (-not (Test-Path $SqlFile)) {
    Write-Host "ERROR: SQL init file not found:" -ForegroundColor Red
    Write-Host "  $SqlFile" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# Helper functions to run psql commands in either mode
# ------------------------------------------------------------------
function Invoke-PsqlCommand {
    param([string]$Db, [string]$Sql)
    if ($UseDocker) {
        return & docker exec -e "PGPASSWORD=$PgPassword" $DockerContainer `
            psql -h localhost -U $PgUser -d $Db -tAc $Sql 2>&1
    } else {
        $env:PGPASSWORD = $PgPassword
        return & psql -h $PgHost -p $PgPort -U $PgUser -d $Db -tAc $Sql 2>&1
    }
}

function Invoke-PsqlFile {
    param([string]$Db, [string]$FilePath)
    if ($UseDocker) {
        # Copy the SQL file into the container then execute it
        & docker cp $FilePath "${DockerContainer}:/tmp/init-restaurant.sql" | Out-Null
        return & docker exec -e "PGPASSWORD=$PgPassword" $DockerContainer `
            psql -h localhost -U $PgUser -d $Db -v ON_ERROR_STOP=1 -f /tmp/init-restaurant.sql 2>&1
    } else {
        $env:PGPASSWORD = $PgPassword
        return & psql -h $PgHost -p $PgPort -U $PgUser -d $Db -v ON_ERROR_STOP=1 -f $FilePath 2>&1
    }
}

# ------------------------------------------------------------------
# Step 1 - Check whether restaurant_db already exists
# ------------------------------------------------------------------
Write-Host ""
Write-Host "Step 1: Checking if '$TargetDb' already exists..." -ForegroundColor Yellow

$checkResult = Invoke-PsqlCommand -Db "postgres" -Sql "SELECT 1 FROM pg_database WHERE datname='$TargetDb';"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot connect to PostgreSQL." -ForegroundColor Red
    Write-Host "  Verify credentials and that the server is running." -ForegroundColor Red
    Write-Host $checkResult -ForegroundColor Red
    exit 1
}

$skipCreate = $false

if (($checkResult | Out-String).Trim() -eq "1") {
    Write-Host "  '$TargetDb' already exists." -ForegroundColor Green
    $recreate = Read-Host "  Drop and recreate? This will DELETE all data. (y/N)"
    if ($recreate -ieq "y") {
        Write-Host "  Dropping '$TargetDb'..." -ForegroundColor Yellow
        Invoke-PsqlCommand -Db "postgres" -Sql "DROP DATABASE IF EXISTS $TargetDb;" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to drop database." -ForegroundColor Red
            exit 1
        }
        Write-Host "  Dropped." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Skipping creation - will run init SQL on existing database." -ForegroundColor Cyan
        $skipCreate = $true
    }
} else {
    Write-Host "  '$TargetDb' does not exist - will create it." -ForegroundColor Yellow
}

# ------------------------------------------------------------------
# Step 2 - Create restaurant_db
# ------------------------------------------------------------------
if (-not $skipCreate) {
    Write-Host ""
    Write-Host "Step 2: Creating database '$TargetDb'..." -ForegroundColor Yellow

    Invoke-PsqlCommand -Db "postgres" -Sql "CREATE DATABASE $TargetDb;" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create '$TargetDb'." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Created '$TargetDb' successfully." -ForegroundColor Green
}

# ------------------------------------------------------------------
# Step 3 - Run init SQL (creates schema and inserts seed data)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "Step 3: Running init SQL (schema + seed data)..." -ForegroundColor Yellow
Write-Host "  Source : $SqlFile"
Write-Host "  Note   : This may take a moment (200 restaurants + all menu items)..."

$initOutput = Invoke-PsqlFile -Db $TargetDb -FilePath $SqlFile
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: SQL init script failed." -ForegroundColor Red
    Write-Host $initOutput -ForegroundColor Red
    exit 1
}
Write-Host "  Schema and seed data applied successfully." -ForegroundColor Green

# ------------------------------------------------------------------
# Step 4 - Verify row counts
# ------------------------------------------------------------------
Write-Host ""
Write-Host "Step 4: Verifying inserted data..." -ForegroundColor Yellow

$restaurantCount = (Invoke-PsqlCommand -Db $TargetDb -Sql "SELECT COUNT(*) FROM restaurants;"      | Out-String).Trim()
$categoryCount   = (Invoke-PsqlCommand -Db $TargetDb -Sql "SELECT COUNT(*) FROM menu_categories;"  | Out-String).Trim()
$itemCount       = (Invoke-PsqlCommand -Db $TargetDb -Sql "SELECT COUNT(*) FROM menu_items;"       | Out-String).Trim()

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Setup Complete!"                            -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Restaurants     : $restaurantCount"
Write-Host "  Menu Categories : $categoryCount"
Write-Host "  Menu Items      : $itemCount"
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Connection string for local dev:" -ForegroundColor Cyan
Write-Host "  postgresql://${PgUser}:${PgPassword}@${PgHost}:${PgPort}/${TargetDb}" -ForegroundColor White
Write-Host ""
Write-Host "Set POSTGRES_DB=restaurant_db when running restaurant-menu-service locally." -ForegroundColor Cyan
Write-Host ""

# Cleanup env var if set
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
