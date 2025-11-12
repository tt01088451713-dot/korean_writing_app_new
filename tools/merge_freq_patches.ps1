
<# 
merge_freq_patches.ps1
--------------------------------------------------------------------
패치본(freq_patch_output\json)을 원본(assets\data\letters)로 안전 반영합니다.
- 원본 백업(폴더+ZIP)
- 해시 비교로 변경/신규 파일만 덮어쓰기
- 요약 CSV 경로 안내
사용법(관리자 권한 불필요):
  1) PowerShell에서 프로젝트 루트로 이동: cd C:\korean_writing_app_new
  2) 실행: .\tools\merge_freq_patches.ps1
옵션:
  -PatchDir <경로>  : 패치본 폴더(기본: .\freq_patch_output\json)
  -TargetDir <경로> : 타깃 폴더(기본: .\assets\data\letters)
  -Report    <경로> : 요약 CSV 경로(기본: .\freq_patch_output\summary.csv)
#>

param(
  [string]$PatchDir = ".\freq_patch_output\json",
  [string]$TargetDir = ".\assets\data\letters",
  [string]$Report = ".\freq_patch_output\summary.csv"
)

function Ensure-Path([string]$p) {
  if (-not (Test-Path $p)) {
    throw "경로가 존재하지 않습니다: $p"
  }
}

# 1) 경로 체크
Ensure-Path $PatchDir
Ensure-Path $TargetDir

# 2) 백업(타임스탬프)
$ROOT = Get-Location
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_DIR = Join-Path $ROOT ("backup_letters_before_freq_" + $ts)
New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
Copy-Item -Path (Join-Path $TargetDir '*.json') -Destination $BACKUP_DIR -Force
# ZIP 압축
$BACKUP_ZIP = "$BACKUP_DIR.zip"
Compress-Archive -Path (Join-Path $BACKUP_DIR '*') -DestinationPath $BACKUP_ZIP -Force

Write-Host "원본 백업 완료:" $BACKUP_ZIP -ForegroundColor Green

# 3) 변경 파일 탐지(해시 비교)
$patchedFiles = Get-ChildItem $PatchDir -Filter *.json
$diffList = @()

foreach ($p in $patchedFiles) {
  $orig = Join-Path $TargetDir $p.Name
  if (Test-Path $orig) {
    $h1 = Get-FileHash $p.FullName -Algorithm SHA256
    $h2 = Get-FileHash $orig -Algorithm SHA256
    if ($h1.Hash -ne $h2.Hash) {
      $diffList += $p.Name
    }
  } else {
    $diffList += $p.Name  # 신규 파일
  }
}

if ($diffList.Count -eq 0) {
  Write-Host "해시 기준 변경된 파일이 없습니다. 종료합니다." -ForegroundColor Yellow
  return
}

Write-Host "변경/신규 파일 목록:" -ForegroundColor Cyan
$diffList | ForEach-Object { Write-Host " - $_" }

# 4) (선택) 특정 파일만 반영하고 싶으면 아래 주석 해제하고 입력받아 사용
# $select = Read-Host "특정 파일만 반영하려면 파일명(쉼표 구분) 입력, 모두면 엔터"
# if ($select) { $diffList = $select.Split(',') | ForEach-Object { $_.Trim() } }

# 5) 반영
foreach ($name in $diffList) {
  Copy-Item -Path (Join-Path $PatchDir $name) -Destination (Join-Path $TargetDir $name) -Force
}

Write-Host "패치본 반영 완료 → $TargetDir" -ForegroundColor Green
if (Test-Path $Report) {
  Write-Host "요약 CSV 확인: $Report" -ForegroundColor DarkCyan
} else {
  Write-Host "요약 CSV 없음: $Report" -ForegroundColor DarkYellow
}

# 6) 간단 스모크 테스트 가이드
Write-Host "`n스모크 테스트 체크:" -ForegroundColor Magenta
Write-Host " - 앱에서 2.x(글자) 단원 열기 → 정렬/필터에 freq(high/mid/low) 노출 확인"
Write-Host " - 임의로 몇 글자 카드 열어 freq 값/표시 정상 확인"
Write-Host " - 자모(1.x) 단원은 변경 없음(이번 작업 비대상)"
