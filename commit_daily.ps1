# 프로젝트 루트로 이동 (이 스크립트가 루트에 있다고 가정)
Set-Location -Path $PSScriptRoot

# Git/Dart 확인
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error "git not found"; exit 1 }
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { Write-Error "dart not found"; exit 1 }

# 자산 검증
Write-Host "Running asset verify..."
dart run bin/verify_stroke_assets.dart
if ($LASTEXITCODE -ne 0) {
  Write-Error "Verify failed. Fix errors before commit."
  exit 1
}

# 메시지
param([string]$Message)
if ([string]::IsNullOrWhiteSpace($Message)) {
  $Message = "Daily snapshot $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

# 커밋
git add -A
git commit -m "$Message"
if ($LASTEXITCODE -ne 0) {
  Write-Host "[WARN] Nothing to commit or commit failed."
  exit 0
}

# (옵션) push
# git push

Write-Host "[OK] Commit done: $Message"
exit 0
