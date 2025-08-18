@echo off
setlocal enabledelayedexpansion

rem === 프로젝트 루트로 이동 (이 스크립트가 루트에 있다고 가정) ===
cd /d "%~dp0"

rem === Git, Dart 설치 확인 ===
where git >nul 2>nul || (echo [ERROR] git not found & exit /b 1)
where dart >nul 2>nul || (echo [ERROR] dart not found & exit /b 1)

rem === 자산 검증 (실패 시 종료) ===
echo Running asset verify...
dart run bin\verify_stroke_assets.dart
if errorlevel 1 (
  echo [ERROR] Verify failed. Fix errors before commit.
  exit /b 1
)

rem === 커밋 메시지 ===
set MSG=%*
if "%MSG%"=="" set MSG=Daily snapshot %date% %time%

rem === 변경사항 추가 및 커밋 ===
git add -A
git commit -m "%MSG%"
if errorlevel 1 (
  echo [WARN] Nothing to commit or commit failed.
  exit /b 0
)

rem === (옵션) 원격 저장소로 push 하고 싶으면 주석 해제하세요 ===
rem git push

echo [OK] Commit done: %MSG%
exit /b 0
