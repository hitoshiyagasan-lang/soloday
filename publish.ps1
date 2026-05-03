# SoloDay: GitHub へ push +（任意）Vercel に CLI から本番デプロイ
#
#   $env:GITHUB_TOKEN = '<PAT>'
#   # 省略可: $env:VERCEL_TOKEN = '<token>'
#   powershell -ExecutionPolicy Bypass -File .\publish.ps1
#
$ErrorActionPreference = "Stop"
$repoOwner = "hitoshiyagasan-lang"
$repoName = "soloday"

if (-not $env:GITHUB_TOKEN) {
    Write-Error @"
GITHUB_TOKEN が設定されていません。

1. GitHub → Settings → Developer settings → Personal access tokens
   （Classic を推奨: scope に repo にチェック。Fine-grained の場合は「Repository creation」および対象 repo の Contents Read/Write などが必要になります）
2. この PowerShell で実行:
      `$env:GITHUB_TOKEN = '<トークン>'`
3. もう一度 `publish.ps1` を実行してください。
"@
}

$git = "${env:ProgramFiles}\Git\bin\git.exe"
if (-not (Test-Path $git)) {
    Write-Error "Git が見つかりません: $git"
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$headers = @{
    Authorization = "Bearer $($env:GITHUB_TOKEN)"
    Accept        = "application/vnd.github+json"
}

$exists = $false
try {
    $null = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName" -Headers $headers -Method Get -ErrorAction Stop
    $exists = $true
} catch {
    $code = $null
    if ($_.Exception.Response) {
        try { $code = [int]$_.Exception.Response.StatusCode } catch { }
    }
    if ($code -eq 404) {
        $exists = $false
    } elseif ($null -eq $code) {
        throw $_
    } else {
        throw $_
    }
}

if (-not $exists) {
    $payload = @{ name = $repoName; description = "SoloDay — static personal day planner UI"; private = $false; auto_init = $false }
    Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers -Method Post `
        -Body ($payload | ConvertTo-Json -Compress) -ContentType "application/json" | Out-Null
    Write-Host "作成しました: https://github.com/$repoOwner/$repoName"
} else {
    Write-Host "リポジトリは既に存在します: https://github.com/$repoOwner/$repoName"
}

$cleanOrigin = "https://github.com/$repoOwner/$repoName.git"
$authedPush = "https://x-access-token:$($env:GITHUB_TOKEN)@github.com/$repoOwner/$repoName.git"

& $git remote remove origin 2>$null
& $git remote add origin $cleanOrigin

& $git push --force-with-lease $authedPush main:main
if ($LASTEXITCODE -ne 0) {
    Write-Error "git push が失敗しました。"
}

Write-Host "`nGitHub push 済み: https://github.com/$repoOwner/$repoName"

if (-not $env:VERCEL_TOKEN) {
    Write-Host @"

Vercel（ブラウザ）:
  https://vercel.com/new で上記 GitHub を Import → Framework: Other のままで Deploy で公開できます。
  （CLI で本番 URL まで出す場合は `$env:VERCEL_TOKEN` を設定してスクリプトを再実行）
"@
    exit 0
}

$npx = "${env:ProgramFiles}\nodejs\npx.cmd"
if (-not (Test-Path $npx)) {
    Write-Warning "npx が見つかりません ($npx)。Vercel はダッシュボードから Import してください。"
    exit 0
}

Write-Host "`nVercel に CLI から本番デプロイしています …"
Push-Location $root
try {
    & $npx --yes vercel@latest deploy --prod --token $env:VERCEL_TOKEN
    if ($LASTEXITCODE -ne 0) { throw "vercel の終了コード: $LASTEXITCODE" }
} finally {
    Pop-Location
}
