# macOS：改代码（Windows 跑定时）

**Windows** 跑 :10/:30/:50 scrape；**Mac** 只编辑 + git push。

Mac 路径：`~/Projects/Sorting Database`

---

## 日常同步

### Mac 推送

```bash
cd ~/Projects/Sorting\ Database
git checkout main
git pull origin main
# …改代码…
git add -A
git commit -m "your message"
git push origin main
```

### Windows 拉取（另一台）

```powershell
cd "$HOME\Projects\Sorting Database"
git checkout main
git pull origin main
```

或：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pull_windows_updates.ps1
```

完整 Windows 说明：[WINDOWS_SETUP.md](WINDOWS_SETUP.md)

---

## 停掉 Mac 定时

```bash
cd ~/Projects/Sorting\ Database
./scripts/uninstall_mac_schedule.sh
```

---

## 可选：Mac 自己当 scrape 备份机

一般不需要。同一时间只开一台定时。

```bash
chmod +x scripts/*.sh
./scripts/install_mac_schedule.sh
./scripts/run_scrape.sh   # 试跑
```
