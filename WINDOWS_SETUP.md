# Windows = scrape runner · Mac = editor

**分工**

| 设备 | 做什么 |
|------|--------|
| **Windows PC** | 装依赖、存 `.env` / 登录态、Task Scheduler 每 20 分钟跑 scrape |
| **Mac** | 用 Cursor 改代码 → `git commit` + `git push` |

Windows **不要**靠 OneDrive 同步整份工程；用 Git 拉代码。  
`.env`、`.uniuni-auth-state.json`、`.current-batch.json`、`logs/` 已在 `.gitignore`，只留在 Windows 本机。

**重要：同一时间只让一台机器跑定时任务。**  
Windows 正式开跑后，在 Mac 上：

```bash
cd ~/Projects/Sorting\ Database
./scripts/uninstall_mac_schedule.sh
```

---

## A. Mac：日常改代码并推送

```bash
cd ~/Projects/Sorting\ Database
git checkout main
git pull origin main
# …用 Cursor 改代码…
git add -A
git commit -m "your message"
git push origin main
```

然后到 **Windows** 拉最新（见 C 节）。

---

## B. Windows：一次性安装

### 1) 系统

- Windows 10/11，**电源插着**
- 时区：**Eastern Time (US & Canada)**
- 睡眠：插电 **Never**；合盖可灭屏，不要休眠
- 安装 [Git for Windows](https://git-scm.com/download/win)
- 安装 [Python 3.11+](https://www.python.org/downloads/)（勾选 **Add python.exe to PATH**）

### 2) 克隆仓库

```powershell
cd $HOME\Projects
git clone https://github.com/yxwvwxy/Sorting-Database.git "Sorting Database"
cd "Sorting Database"
git checkout main
```

### 3) 虚拟环境 + Playwright

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

### 4) 密钥（只放 Windows）

```powershell
copy .env.example .env
notepad .env
```

至少填：`UNIUNI_USERNAME` / `UNIUNI_PASSWORD`、`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`  
（从 Mac `local.env` / `.env` 手动抄，不要 commit。）

### 5) 试跑

```bat
.\scripts\run_scrape.bat
```

成功：`logs\scrape-YYYYMMDD.log` 末尾有 `Saved scrape snapshot`。  
调试：`.\scripts\run_scrape.bat --headed --dry-run`

### 6) 注册定时（:10 / :30 / :50）

```powershell
cd "$HOME\Projects\Sorting Database"
powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1
```

任务名：`SortingDataScrape20Min-10` / `-30` / `-50`

---

## C. Windows：从 Git 同步最新代码（Mac push 之后）

在 **PowerShell** 里：

```powershell
cd "$HOME\Projects\Sorting Database"
git checkout main
git pull origin main
```

或一键脚本（同样是 pull + 检查 `.venv`）：

```powershell
cd "$HOME\Projects\Sorting Database"
powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

若提示 `requirements.txt` 有变，再跑：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

**不必**每次重装 Playwright。pull 之后下次 :10/:30/:50 自动用新代码。

---

## D. 跑起来之后的行为

- 每小时 **:10 / :30 / :50** ET 各跑一次  
- 每次写入 chute + feed  
- **hourly**：只有当前未满小时会三次更新；整点结束后定稿一次不再改；中断恢复会补齐未定稿的完整小时  
- Query 失败会重试 / 强制重登；整次失败 bat 再开一轮浏览器  
- 上一轮还在跑 → skip（`logs\scrape.lock`；崩溃残留锁约 **15 分钟**后视为过期）  
- UniMap 会话：`.uniuni-auth-state.json`

**Batch**

- **21:10 ET** → 只用已保存 batch，不打开 Slot Assignment  
- **21:30 ET 起**直到 Slot `Batch No` 变化 → 每次打开 Slot 检查  
  - 仍是旧的 → 继续用旧 batch，下次再查  
  - 已变 → 用页面新 batch（D 晚上 → ops day D+1），之后停查直到下一个 21:30  
- Slot 检查失败 → 未确认，后面还要再查  
- 若错过 21:30 且本 ops day 未确认 → 白天也会继续查直到变化  
- 手动：`.\scripts\run_scrape.bat --refresh-batch`

---

## E. 日志与排查

| 位置 | 用途 |
|------|------|
| `logs\scrape-YYYYMMDD.log` | 每次 scrape 输出 |
| 任务计划程序 → 历史记录 | 是否触发 |
| `.\scripts\run_scrape.bat --headed` | 看 UniMap 卡在哪 |

- Overlap skip → exit code **2**  
- 成功 → 日志末尾 `Saved scrape snapshot`  
- 连续失败：确认没人共用 `nj600`；可删 `.uniuni-auth-state.json` 重登  

---

## F. 停用 Windows 定时（回退 Mac）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\unregister_scheduled_tasks.ps1
```

然后在 Mac：`./scripts/install_mac_schedule.sh`
