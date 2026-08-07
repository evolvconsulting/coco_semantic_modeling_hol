## 1. Clone

- [ ] `git clone https://github.com/evolvconsulting/coco_semantic_modeling_hol.git`
- [ ] `cd coco_semantic_modeling_hol`

## 2. Install CoCo Desktop if it's missing

- [ ] download the macOS build from https://www.snowflake.com/en/product/snowflake-coco/downloads/ (Apple Silicon or Intel)
- [ ] open the `.dmg` and drag Snowflake CoCo into Applications
- [ ] launch it, then work through the four-step wizard: welcome → connect → view → theme
- [ ] at connect, enter your account identifier and username, and choose Local OAuth
- [ ] use Open Folder to point CoCo at the repo you just cloned

## 3. Check installed versions

- [ ] `python3 --version` (need 3.10+)
- [ ] `node --version` (need v18+)
- [ ] `npm --version`

## 4. Install Python if it's missing

- [ ] `curl --proto '=https' --tlsv1.2 -sSf https://www.python.org/ftp/python/3.12.7/python-3.12.7-macos11.pkg -o /tmp/python-installer.pkg`
- [ ] `open /tmp/python-installer.pkg`
- [ ] open new terminal, `python3 --version`

## 5. Install Node if it's missing

- [ ] `curl -o /tmp/node-installer.pkg https://nodejs.org/dist/v22.11.0/node-v22.11.0.pkg`
- [ ] `open /tmp/node-installer.pkg`
- [ ] open new terminal, `node --version` / `npm --version`

## 6. Setup the backend with a venv

- [ ] `cd backend`
- [ ] `python3 -m venv venv`
- [ ] `source venv/bin/activate`
- [ ] `pip install -r requirements.txt`

## 7. Frontend setup (new terminal tab)

- [ ] `cd frontend`
- [ ] `npm install`

## 8. Run

- [ ] from repo root: `./run.sh` → starts backend + frontend, open printed `Local:` URL
- [ ] Ctrl+C stops both
