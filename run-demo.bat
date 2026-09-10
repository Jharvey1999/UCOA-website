@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title UCOA local demo

echo.
echo UCOA local demo
echo Repository: %CD%
echo.

where docker >nul 2>&1
if errorlevel 1 (
  echo Docker was not found on PATH. Install Docker Desktop and try again.
  goto :fail
)

docker info >nul 2>&1
if errorlevel 1 (
  echo Docker Desktop is not running or its Linux engine is unavailable.
  echo Start Docker Desktop, wait for it to become ready, and try again.
  goto :fail
)

where node >nul 2>&1
if errorlevel 1 (
  echo Node.js was not found on PATH. Install Node.js and try again.
  goto :fail
)

where npx >nul 2>&1
if errorlevel 1 (
  echo npx was not found on PATH. Install Node.js and try again.
  goto :fail
)

if not exist "package.json" (
  echo package.json was not found. Run this script from the UCOA repository.
  goto :fail
)

if not exist ".env.local" (
  echo .env.local was not found.
  echo Copy .env.example to .env.local and set the local Supabase URL and publishable key.
  goto :fail
)

findstr /B /C:"NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321" /C:"NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321" ".env.local" >nul
if errorlevel 1 (
  echo .env.local does not point to the local Supabase API on port 54321.
  echo Update NEXT_PUBLIC_SUPABASE_URL using the output of "npx --yes supabase status".
  goto :fail
)

findstr /B /C:"NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=" ".env.local" >nul
if errorlevel 1 (
  echo NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY is missing from .env.local.
  goto :fail
)

findstr /B /C:"NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key" ".env.local" >nul
if not errorlevel 1 (
  echo .env.local still contains the publishable-key placeholder.
  goto :fail
)

if not exist "node_modules\next\package.json" (
  echo Installing npm dependencies...
  call npm install
  if errorlevel 1 goto :fail
)

echo Starting local Supabase...
call npx --yes supabase start >nul 2>&1
if errorlevel 1 goto :fail

echo Resetting local migrations and isolated seed...
call npx --yes supabase db reset --local --yes
if errorlevel 1 goto :fail

echo Loading opt-in synthetic demo data...
set "DB_CONTAINER="
for /f "delims=" %%C in ('docker ps --format "{{.Names}}" ^| findstr /B /C:"supabase_db_UCOA-website"') do set "DB_CONTAINER=%%C"
if not defined DB_CONTAINER (
  echo The local Supabase Postgres container was not found.
  goto :fail
)
docker exec -i "%DB_CONTAINER%" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "supabase\demo-seed.sql"
if errorlevel 1 goto :fail

echo.
echo Demo database is ready.
echo Public app: http://localhost:3000
echo Supabase Studio: http://127.0.0.1:54323
echo.
echo Starting Next.js. Press Ctrl+C to stop the app.
echo.
call npm run dev
set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo Next.js stopped with exit code %EXIT_CODE%.
pause
exit /b %EXIT_CODE%

:fail
echo.
echo UCOA demo setup failed. No hosted Supabase project was changed.
pause
exit /b 1
