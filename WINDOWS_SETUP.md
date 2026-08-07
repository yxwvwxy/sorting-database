# Windows = scrape runner · Mac = editor

**分工**

| 设备 | 做什么 |
|------|--------|
| **Windows PC** | 装依赖、存 `.env` / 登录态、Task Scheduler 每 20 分钟跑 scrape |
| **Mac** | 用 Cursor/VS Code 改代码 → `git commit` + `git push` |

Windows **不要**靠 OneDrive 同步整份工程当主流程；用 Git 拉代码。  
`.env`、`.uniuni-auth-state.json`、`.current-batch.json`、`logs/` 已在 `.gitignore`，只留在 Windows 本机。

**重要：同一时间只让一台机器跑定时任务。**  
Windows 开始正式跑之后，在 Mac 上卸载 LaunchAgent，避免双开抢 UniMap / 写双份数据：

```bash
# on Mac
./scripts/uninstall_mac_schedule.sh
```

---

## A. Mac：日常改代码

```bash
cd "/path/to/Sorting Database"
# edit…
git add -A
git commit -m "your message"
git push -u origin HEAD
```

建议推到 `main`（或你约定的发布分支）。Windows 只 pull 这个分支。

私有仓库：Windows 首次 `git clone` 需要登录 GitHub（浏览器或 PAT）。

---

## B. Windows：一次性安装

### 1) 系统

- Windows 10/11，**电源插着**
- 时区设为 **Eastern Time (US & Canada)**（与 NJ ops 一致）
- 睡眠：插电时 **Never**；合盖可灭屏，但不要休眠
- 安装 [Git for Windows](https://git-scm.com/download/win)
- 安装 [Python 3.11+](https://www.python.org/downloads/)（勾选 **Add python.exe to PATH**）

### 2) 克隆仓库

在 PowerShell（路径按你习惯改）：

```powershell
cd $HOME\Projects
git clone https://github.com/yxwvwxy/sorting-database.git "Sorting Database"
cd "Sorting Database"
git checkout main
```

若默认分支还不是 `main`，改成你们实际用的分支名。

### 3) 虚拟环境 + Playwright

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

### 4) 密钥（只放 Windows）

```powershell
copy .env.example .env
notepad .env
```

至少填：

- `UNIUNI_USERNAME` / `UNIUNI_PASSWORD`
- `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`

（可从 Mac 上现有 `local.env` / `.env` **手动抄**，不要 commit。）

### 5) 试跑一次

```bat
.\scripts\run_scrape.bat
```

成功则 `logs\scrape-YYYYMMDD.log` 末尾有 `Saved scrape snapshot`。  
调试可看浏览器：

```bat
.\scripts\run_scrape.bat --headed --dry-run
```

### 6) 注册定时任务（:10 / :30 / :50）

**用管理员 PowerShell**（部分环境需要）：

```powershell
cd "$HOME\Projects\Sorting Database"
powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_tasks.ps1
```

会创建：

- `SortingDataScrape20Min-10`
- `SortingDataScrape20Min-30`
- `SortingDataScrape20Min-50`

在「任务计划程序」里可确认下次运行时间。

---

## C. Windows：每次 Mac 推送后更新代码

在仓库根目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

默认 `git pull` 当前分支并检查 `.venv` 仍在。  
若 `requirements.txt` 有变，脚本会提示再跑 `setup_windows.ps1`。

或手动：

```powershell
git pull
```

**不必**每次重装 Playwright；只有依赖大变时才重跑 setup。

---

## D. 行为说明（跑起来之后）

- 每小时 **:10 / :30 / :50** ET 各跑一次  
- 每次写入 chute + feed（`scraped_at` 区分历史）  
- **hourly**：只有**当前未满小时**会在 :10/:30/:50 更新；整点结束后那一小时写入一次后不再改；中断恢复时补齐尚未定稿的完整小时  


- Query 失败会自动重试 / 强制重新登录；整次失败 bat 还会再开一轮浏览器  
- 上一轮还在跑时，下一轮会 skip（`logs\scrape.lock`）  
- UniMap 会话：`.uniuni-auth-state.json`（过期会重新登录）

Batch：

- **21:10 ET**：用已保存 batch，不打开 Slot Assignment  
- **21:30 ET 起**：轮询 Slot Assignment 直到 Batch No 变化  
- 手动：`.\scripts\run_scrape.bat --refresh-batch`

---

## E. 日志与排查

| 位置 | 用途 |
|------|------|
| `logs\scrape-YYYYMMDD.log` | 每次 scrape 输出 |
| 任务计划程序 → 历史记录 | 任务是否被触发 |
| `.\scripts\run_scrape.bat --headed` | 肉眼看 UniMap 卡在哪 |

连续失败时：确认没人在别处用同一 `nj600` 账号；必要时删 `.uniuni-auth-state.json` 再跑一次让它重登。

---

## F. 停用 Windows 定时（回退 Mac 时）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\unregister_scheduled_tasks.ps1
```

然后在 Mac 再执行 `./scripts/install_mac_schedule.sh`。
