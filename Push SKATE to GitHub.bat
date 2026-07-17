@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Pushes this SKATE folder to https://github.com/SixSigmaEngineer/SKATE
rem Usage:
rem   Double-click: creates a timestamped commit message.
rem   Command line: "Push SKATE to GitHub.bat" "Describe this update"

set "REPO_URL=https://github.com/SixSigmaEngineer/SKATE.git"
set "BRANCH=main"

cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git is not installed or is not available on PATH.
    echo Install Git for Windows, then run this file again.
    goto :fail
)

if not exist ".git\" (
    echo Initializing the local SKATE repository...
    git init
    if errorlevel 1 goto :git_fail
)

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "CURRENT_ORIGIN=%%R"
if not defined CURRENT_ORIGIN (
    echo Connecting to %REPO_URL%...
    git remote add origin "%REPO_URL%"
    if errorlevel 1 goto :git_fail
) else if /I not "%CURRENT_ORIGIN%"=="%REPO_URL%" (
    echo ERROR: This repository already has a different origin:
    echo   %CURRENT_ORIGIN%
    echo Expected:
    echo   %REPO_URL%
    echo The remote was not changed automatically.
    goto :fail
)

git config user.name >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git does not have a user name configured.
    echo Run: git config --global user.name "Your Name"
    goto :fail
)

git config user.email >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git does not have an email configured.
    echo Run: git config --global user.email "you@example.com"
    goto :fail
)

echo Staging SKATE changes...
git add --all
if errorlevel 1 goto :git_fail

rem Refuse to upload local credentials, private notes, generated models, or logs
rem even if the ignore rules are accidentally changed later.
set "UNSAFE_FILES="
for /f "delims=" %%F in ('git diff --cached --name-only -- settings.json conversations sessions transcripts models/whisper tools/ffmpeg.exe 2^>nul') do set "UNSAFE_FILES=1"
if defined UNSAFE_FILES (
    echo ERROR: Private or generated files were staged for upload.
    echo Review settings.json, private vault folders, transcripts, models, and tools.
    git diff --cached --name-only -- settings.json conversations sessions transcripts models/whisper tools/ffmpeg.exe
    goto :fail
)

git diff --cached --check
if errorlevel 1 (
    echo ERROR: Git found whitespace errors that should be reviewed before upload.
    goto :fail
)

git diff --cached --quiet
if not errorlevel 1 (
    echo No local changes need to be committed.
    goto :push_existing
)

if "%~1"=="" (
    set "COMMIT_MESSAGE=SKATE update %DATE% %TIME%"
) else (
    set "COMMIT_MESSAGE=%~1"
)

echo Creating commit: %COMMIT_MESSAGE%
git commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 goto :git_fail

:push_existing
git branch -M "%BRANCH%"
if errorlevel 1 goto :git_fail

echo Uploading SKATE to GitHub...
echo You may be asked to sign in to GitHub on the first push.
git push --set-upstream origin "%BRANCH%"
if errorlevel 1 goto :git_fail

echo.
echo SUCCESS: SKATE is up to date on GitHub.
echo https://github.com/SixSigmaEngineer/SKATE
echo.
pause
exit /b 0

:git_fail
echo.
echo ERROR: Git could not complete the upload.
echo Review the message above. Your local files were not deleted or reset.

:fail
echo.
pause
exit /b 1
