## 0. Clone

- [ ] `git clone https://github.com/evolvconsulting/c1_lab.git`
- [ ] `cd c1_lab`

## 1. Check installed versions

- [ ] `python --version` (need 3.10+)
- [ ] `node --version` (need v18+)
- [ ] `npm --version`

## 2. Install Python if it's missing

- [ ] `winget install --id Python.Python.3.12`
- [ ] close/reopen PowerShell, `python --version`
- [ ] if still not found: Start Menu → "Manage App Execution Aliases" → turn OFF `python.exe`/`python3.exe`

## 3. Install Node if it's missing

- [ ] `winget install --id OpenJS.NodeJS.LTS`
- [ ] close/reopen PowerShell, `node --version` / `npm --version`

## 4. Setup the backend with a venv

- [ ] `cd backend`
- [ ] `python -m venv venv`
- [ ] `venv\Scripts\activate`
- [ ] `pip install -r requirements.txt`

## 5. Frontend setup (new PowerShell window)

- [ ] `cd frontend`
- [ ] `npm install`

## 6. Run

- [ ] from repo root: `.\run.ps1` → starts backend + frontend, open printed `Local:` URL
- [ ] Ctrl+C stops both
