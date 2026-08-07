> **One PowerShell window, start to finish.** Every step below assumes you're at
> the repo root (`coco_semantic_modeling_hol\`). Where a step moves you elsewhere,
> its last box brings you back, so you can just work down the list. Steps 4 and 5
> are the exception — installing Python or Node needs a fresh window, so `cd` back
> to the repo root when you reopen.

## 1. Clone

- [ ] `git clone https://github.com/evolvconsulting/coco_semantic_modeling_hol.git`
- [ ] `cd coco_semantic_modeling_hol`

## 2. Install CoCo Desktop if it's missing

- [ ] download the Windows build from https://www.snowflake.com/en/product/snowflake-coco/downloads/ (Intel/AMD or ARM — take the user installer)
- [ ] run the `.exe` and accept the default install location
- [ ] launch it, then work through the four-step wizard: welcome → connect → view → theme
- [ ] at connect, enter your account identifier and username, and choose Local OAuth
- [ ] use Open Folder to point CoCo at the repo you just cloned

## 3. Check installed versions

- [ ] `python --version` (need 3.10+)
- [ ] `node --version` (need v18+)
- [ ] `npm --version`

## 4. Install Python if it's missing

- [ ] `winget install --id Python.Python.3.12`
- [ ] close/reopen PowerShell, `python --version`
- [ ] if still not found: Start Menu → "Manage App Execution Aliases" → turn OFF `python.exe`/`python3.exe`

## 5. Install Node if it's missing

- [ ] `winget install --id OpenJS.NodeJS.LTS`
- [ ] close/reopen PowerShell, `node --version` / `npm --version`

## 6. Setup the backend with a venv

- [ ] `cd backend`
- [ ] `python -m venv venv`
- [ ] `venv\Scripts\activate`
- [ ] `pip install -r requirements.txt`
- [ ] `cd ..`

## 7. Configure `backend/.env`

- [ ] `copy backend\.env.example backend\.env`
- [ ] fill it in — the first three come from the credentials you were issued, the rest are the same for everyone:

```
SNOWFLAKE_ACCOUNT=ORGNAME-ACCOUNT
SNOWFLAKE_USER=USER
SNOWFLAKE_PASSWORD=<as issued>
SNOWFLAKE_WAREHOUSE=HOL_DEALER360_WH
SNOWFLAKE_ROLE=HOL_PARTICIPANT
SNOWFLAKE_DATABASE=HOL_DEALER360
SNOWFLAKE_SCHEMA=CORE
```

- [ ] leave no blanks — the backend fails to connect if any value is empty

## 8. Frontend setup

- [ ] `cd frontend`
- [ ] `npm install`
- [ ] `cd ..`

## 9. Run

- [ ] `.\run.ps1` → starts backend + frontend, open printed `Local:` URL
- [ ] Ctrl+C stops both

`run.ps1` activates the venv and starts both servers itself, so you don't need a
second window and you don't need the venv active when you call it.
