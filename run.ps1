$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$backend = Start-Job -ScriptBlock {
    Set-Location "$using:PSScriptRoot\backend"
    & .\venv\Scripts\Activate.ps1
    python main.py
}

$frontend = Start-Job -ScriptBlock {
    Set-Location "$using:PSScriptRoot\frontend"
    npm run dev
}

try {
    while ($true) {
        Receive-Job $backend -ErrorAction SilentlyContinue | ForEach-Object { "[backend] $_" }
        Receive-Job $frontend -ErrorAction SilentlyContinue | ForEach-Object { "[frontend] $_" }
        Start-Sleep -Milliseconds 300
    }
}
finally {
    Stop-Job $backend, $frontend -ErrorAction SilentlyContinue
    Remove-Job $backend, $frontend -ErrorAction SilentlyContinue
}
