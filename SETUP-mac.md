## 0. Clone

- [ ] `git clone https://github.com/evolvconsulting/c1_lab.git`
- [ ] `cd c1_lab`

## 1. Check installed versions

- [ ] `python3 --version` (need 3.10+)
- [ ] `node --version` (need v18+)
- [ ] `npm --version`

## 2. Install Python if it's missing

- [ ] `curl --proto '=https' --tlsv1.2 -sSf https://www.python.org/ftp/python/3.12.7/python-3.12.7-macos11.pkg -o /tmp/python-installer.pkg`
- [ ] `open /tmp/python-installer.pkg`
- [ ] open new terminal, `python3 --version`

## 3. Install Node if it's missing

- [ ] `curl -o /tmp/node-installer.pkg https://nodejs.org/dist/v22.11.0/node-v22.11.0.pkg`
- [ ] `open /tmp/node-installer.pkg`
- [ ] open new terminal, `node --version` / `npm --version`

## 4. Setup the backend with a venv

- [ ] `cd backend`
- [ ] `python3 -m venv venv`
- [ ] `source venv/bin/activate`
- [ ] `pip install -r requirements.txt`

## 5. Frontend setup (new terminal tab)

- [ ] `cd frontend`
- [ ] `npm install`

## 6. Run

- [ ] from repo root: `./run.sh` → starts backend + frontend, open printed `Local:` URL
- [ ] Ctrl+C stops both

