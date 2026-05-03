# SoloDay

静的な 1 ページのプラン UI（`/index.html`。元は `soloday.html` と同一内容）。

## GitHub と Vercel へ自動公開する

ブラウザのログインはあなたにしかできないため、このリポジトリ付属の **`publish.ps1`** は **GitHub PAT（および任意で Vercel トークン）** が環境変数にあるときだけ、API でリポジトリ作成〜`git push`〜（任意で）`vercel` まで自動で実行します。

1. GitHub で [Personal Access Token（Classic で `repo`）](https://github.com/settings/tokens) を発行します。
2. PowerShell で次のように実行します（`<...>` は差し替え。トークンは画面録画しないでください）。

```powershell
cd $HOME\.cursor\soloday-web
$env:GITHUB_TOKEN = '<GitHub PAT>'
# 省略可 ↓ （あるとその場で CLI から本番 URL を取得）
$env:VERCEL_TOKEN = '<Vercel token https://vercel.com/account/tokens>'
powershell -ExecutionPolicy Bypass -File .\publish.ps1
```

`VERCEL_TOKEN` を付けなかった場合でも、ログに出した GitHub の URL を [Vercel New Project](https://vercel.com/new) で Import すれば同じソースでホストできます。
