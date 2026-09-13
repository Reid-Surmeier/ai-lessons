# The Telephone Website: set up Windows. Mirrors setup.sh stage for stage.
# Run:  powershell -ExecutionPolicy Bypass -File .\setup.ps1
$ErrorActionPreference = 'Stop'
$Total = 8; $script:I = 0
$Cfg = Join-Path $env:USERPROFILE '.config\telephone-lesson'; New-Item -ItemType Directory -Force -Path $Cfg | Out-Null
$EnvFile = Join-Path $Cfg 'setup.env'
$Saved = @{}; if (Test-Path $EnvFile) { Get-Content $EnvFile | ForEach-Object { $k,$v = $_ -split '=',2; $Saved[$k] = $v } }

function Stage($name) { Clear-Host; $script:I++; Write-Host "`n▸ Stage $script:I/$Total · $name" -ForegroundColor Blue }
function Say($t)  { Write-Host "  $t" }
function Step($t) { Write-Host "  • $t" -ForegroundColor Blue }
function Note($t) { Write-Host "  $t" -ForegroundColor DarkGray }
function Warn($t) { Write-Host "  ⚠ $t" -ForegroundColor Yellow }
function Pause2($t = 'Press Enter to continue') { Read-Host "  $t" | Out-Null }
function Confirm2($q) { (Read-Host "  ? $q [y/N]") -match '^[Yy]' }
function OpenUrl($u) { Write-Host "  ↗ opening $u" -ForegroundColor Green; Start-Process $u }
function Ask($key, $prompt) {
  $cur = $Saved[$key]
  $v = if ($cur) { Read-Host "  $prompt [Enter keeps $cur]" } else { Read-Host "  $prompt" }
  if (-not $v -and $cur) { $v = $cur }
  $Saved[$key] = $v; ($Saved.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) | Set-Content $EnvFile
  return $v
}
function AskSecret($prompt) {
  $s = Read-Host "  $prompt" -AsSecureString
  return [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}
function RefreshPath { $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Clear-Host
Write-Host "`n  The Telephone Website: set up Windows" -ForegroundColor Blue
Note "$Total stages. You drive the browser; this wizard says exactly what to do."
Note "Stop any time with Ctrl-C and re-run later: it skips what is already done."
if (-not (Has winget)) { Warn "winget is missing. Install 'App Installer' from the Microsoft Store, then re-run."; exit 1 }
Pause2 'Ready to start?'

# ── 1. GitHub account
Stage 'GitHub account'
Say 'GitHub is where your finished website will be hosted, for free.'
if (-not (Confirm2 'Do you already have a GitHub account?')) {
  OpenUrl 'https://github.com/signup'
  Step 'Sign up with your school email. Pick a short username: it becomes part of your site address.'
  Step 'Verify the email GitHub sends you, then come back here.'
  Pause2
}
$null = Ask 'GITHUB_USERNAME' 'Type your GitHub username exactly:'

# ── 2. git, gh, node
Stage 'git, GitHub CLI, Node'
Say 'git tracks files, gh talks to GitHub, Node runs the skill installer. winget may ask you to approve.'
foreach ($p in 'Git.Git','GitHub.cli','OpenJS.NodeJS.LTS') {
  winget install --id $p -e --accept-package-agreements --accept-source-agreements --silent
  if ($LASTEXITCODE -notin 0, -1978335189) { Warn "winget returned $LASTEXITCODE for $p" }   # -1978335189 = already installed
}
RefreshPath
foreach ($c in 'git','gh','node') { if (-not (Has $c)) { Warn "$c not found yet. Close this window, open a new PowerShell, re-run the wizard."; exit 1 } }
Note ("git " + (git --version) + " · node " + (node --version))
$name  = Ask 'GIT_NAME'  'Your name, as it should appear on your work (e.g. Ada Lovelace):'
$email = Ask 'GIT_EMAIL' 'The email you used for GitHub:'
git config --global user.name $name; git config --global user.email $email; git config --global init.defaultBranch main

# ── 3. Windows sandbox note (Codex runs natively, no WSL)
Stage 'About Codex on Windows'
Say 'Codex runs natively in PowerShell. Windows 11 is recommended; Windows 10 works best-effort.'
Note 'If Codex later offers to set up its Windows sandbox and asks for admin approval, say yes.'
Pause2

# ── 4. Codex
Stage 'Codex (the coding agent)'
if (Has codex) { Note ("Codex is already installed: " + (codex --version)) }
else {
  Say "Installing Codex with OpenAI's official installer."
  Invoke-Expression (Invoke-RestMethod 'https://chatgpt.com/codex/install.ps1')
  RefreshPath
  if (-not (Has codex)) { Warn 'codex not found on PATH. Open a new PowerShell and re-run the wizard.'; exit 1 }
  Note ("Installed " + (codex --version))
}

# ── 5. ChatGPT sign-in
Stage 'Sign Codex in with ChatGPT'
Say 'Codex signs in with a ChatGPT account on the Plus plan ($20/month). A free account will not work.'
if (-not (Confirm2 'Do you already have ChatGPT Plus?')) { OpenUrl 'https://chatgpt.com/'; Step 'Create an account, then upgrade to Plus (profile menu -> Upgrade plan). Come back when it says Plus.'; Pause2 }
Say "A browser window will open. Choose 'Sign in with ChatGPT' and approve."
Pause2 'Press Enter to start codex login'
codex login
if ($LASTEXITCODE -ne 0) { Warn "codex login did not finish. You can run 'codex login' yourself later." }

# ── 6. GitHub token
Stage 'A GitHub token the agent can use'
Say 'The agent needs permission to create your repo and turn on GitHub Pages.'
Say "You'll make a fine-grained token that expires in 30 days."
OpenUrl 'https://github.com/settings/personal-access-tokens/new'
Step 'Token name: telephone-lesson.   Expiration: 30 days.'
Step 'Repository access: All repositories.'
Step 'Permissions → Repository permissions: set these three to Read and write:'
Step '   Administration · Contents · Pages    (Metadata turns on by itself)'
Step 'Click Generate token, then copy it. It starts with github_pat_.'
$tok = AskSecret 'Paste the token (nothing will show as you paste):'
$tok | gh auth login --with-token
if ($LASTEXITCODE -ne 0) { Warn 'gh could not use that token. Re-run the wizard and paste it again.'; exit 1 }
$tok = $null
gh auth setup-git
gh auth status

# ── 7. Skills
Stage 'Install the skills'
Say "Skills are instruction files the agent reads. Two sets: Matt Pocock's (grill-me lives there) and this lesson's."
npx -y skills@latest add mattpocock/skills -a codex -g -y
npx -y skills@latest add Reid-Surmeier/ai-lessons -a codex -g -y

# ── 8. Check
Stage 'Check everything'
$ok = $true
foreach ($c in 'git','gh','node','codex') { if (Has $c) { Write-Host "  ✓ $c" -ForegroundColor Green } else { Write-Host "  ✗ $c missing" -ForegroundColor Red; $ok = $false } }
$login = gh api user --jq .login 2>$null
if ($login) { Write-Host "  ✓ signed in to GitHub as $login" -ForegroundColor Green } else { Write-Host '  ✗ GitHub sign-in' -ForegroundColor Red; $ok = $false }
foreach ($s in 'grilling','grill-me','telephone') {
  if (Test-Path (Join-Path $env:USERPROFILE ".agents\skills\$s\SKILL.md")) { Write-Host "  ✓ skill $s" -ForegroundColor Green } else { Write-Host "  ✗ skill $s" -ForegroundColor Red; $ok = $false }
}
if (-not $ok) { Warn 'Something is missing: re-run this wizard, it skips what is done.' }
Say ''
Say 'Next: on lesson day, open PowerShell and type   codex   then   $telephone'
Write-Host "`n  ✓ Setup complete`n" -ForegroundColor Green
