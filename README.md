# dotfiles

我的 shell 與 git 環境設定。

**這個 repo 是「跨機器的工具庫」，不是這台機器的設定備份。**
所以它只放不隨環境改變的東西 —— 身分（email）、機器專屬路徑都不在這裡。

---

## 在新機器上安裝

```bash
git clone <這個 repo> ~/dotfiles
cd ~/dotfiles

./install.sh -n     # 乾跑：只顯示會做什麼，不動任何檔案。建議先跑這個
./bootstrap.sh      # 裝套件、clone oh-my-zsh 與 plugin，並產生身分範本
                    #   需要網路與 sudo，一台機器只跑一次
vim ~/.gitconfig.local   # ★ 填入 email，不填的話 git commit 會報錯（見下）
./install.sh        # 建立符號連結。可以無限次重跑
exec zsh            # 生效
```

### 各步驟實際做什麼

| 步驟 | 做什麼 | 需要 sudo | 可重跑 |
|---|---|---|---|
| `bootstrap.sh` | `apt install` 套件；`git clone` oh-my-zsh、powerlevel10k、兩個 zsh plugin；產生 `~/.gitconfig.local` 範本 | ✅ | ✅（已存在的會跳過） |
| `install.sh` | 建立三個符號連結：`.zshrc`、`.p10k.zsh`、`.gitconfig` | ❌ | ✅（已正確連結的顯示「已是最新」，不會重複備份） |

### `install.sh` 到底怎麼運作（重跑安全）

對每個要連結的檔案，它判斷三種情況：

| 情況 | 動作 |
|---|---|
| 目標**已經是**指向正確位置的符號連結 | **什麼都不做**，顯示「已是最新」 |
| 目標存在，但是實體檔案或指向別處的連結 | **`mv` 搬到備份區**（不是 `rm`），再建立新連結 |
| 目標不存在 | 直接建立連結 |

三個保證：

1. **絕不覆蓋、絕不刪除。** 用的是 `mv` 不是 `rm`，原檔永遠搬得回來
2. **冪等。** 已經正確的檔案會提早跳過，重跑一百次結果都一樣
3. **不產生垃圾。** 備份目錄只在「真的有東西要備份」時才建立，
   所以重跑不會每次都多一個空資料夾

實際重跑的輸出長這樣（只有壞掉的那個被處理）：

```
$ ./install.sh
  已備份 .zshrc → /home/bc/.dotfiles-backup/20260815-195529/
  已連結 ~/.zshrc → /home/bc/dotfiles/zsh/.zshrc
  已是最新 .p10k.zsh          ← 沒被碰
  已是最新 .gitconfig         ← 沒被碰
```

備份目錄以**每次執行的時間戳**命名，所以歷次備份不會互相覆蓋。

### ⚠️ 一定要填 `~/.gitconfig.local`

`git/.gitconfig` 設了 `user.useConfigOnly = true`，而身分不在這個 repo 裡。
所以 `~/.gitconfig.local` 沒填的話，第一次 commit 會直接失敗：

```
fatal: user.email is not set and useConfigOnly is set
```

**這是刻意的。** 沒有這道防線的話，git 會默默用 `<使用者名>@<主機名>` 湊一個 email
然後永久寫進 commit 歷史 —— 那個 email 在公開 repo 上任何人都看得到。

```ini
# ~/.gitconfig.local
[user]
	name = Ben
	email = 你的email@example.com
```

### 只跑 `install.sh`、不跑 `bootstrap.sh` 也可以

沒有 sudo 權限、或不想動系統套件時，可以只建立符號連結。

設定檔會**優雅降級**：`.zshrc` 只載入實際存在的 plugin，
所以在還沒裝 fzf / zsh-autosuggestions / zsh-syntax-highlighting 的機器上
**不會噴任何警告**，只是少了那些功能。

代價是沒有 fzf 的 `Ctrl-R`、沒有灰字歷史建議、沒有語法上色。

---

## 安裝後驗證

整段複製貼上，全部應該顯示 ✓：

```bash
# 1. 符號連結是否正確
for f in .zshrc .p10k.zsh .gitconfig; do
  [[ -L ~/$f ]] && echo "✓ ~/$f → $(readlink ~/$f)" || echo "✗ ~/$f 不是符號連結"
done

# 2. git 身分是否載入（應顯示你的 email，來源是 .gitconfig.local）
git config --show-origin --get user.email

# 3. git 行為設定是否生效
git config --get rerere.enabled     # 應為 true
git config --get merge.conflictstyle # 應為 zdiff3

# 4. alias 是否載入
alias gpush gpull grl gbv

# 5. 危險 alias 是否已移除（應該全部 command not found）
for a in gwipe gpristine grhh gp gl; do
  alias $a >/dev/null 2>&1 && echo "✗ $a 還在" || echo "✓ $a 已移除"
done

# 6. install.sh 冪等性（連跑兩次，第二次應全部顯示「已是最新」）
cd ~/dotfiles && ./install.sh && ./install.sh
```

**最後一步：開一個全新的終端機視窗。** 上面的檢查跑在既有 shell 裡，
有些問題（p10k 即時提示、gitstatus）只有在真正的新 session 才看得出來。

---

## `bootstrap.sh` 會裝什麼

### 系統套件（`apt install`）

| 套件 | 是什麼 | 取代 | 為什麼要它 |
|---|---|---|---|
| `zsh` | shell 本體 | bash | 這整套設定的基礎 |
| `git` | 版本控制 | — | |
| `curl` | 下載工具 | — | 安裝腳本常需要 |
| `vim` | 終端機編輯器 | — | `EDITOR` 指向它，git commit 會開它 |
| `tmux` | 終端機多工 | — | 斷線後 session 不會死；一個視窗開多個面板 |
| **`fzf`** | **模糊搜尋器** | — | **「快速 navigate terminal」的核心答案** |
| **`zoxide`** | **智慧 cd** | `cd` | 記住你常去的目錄，`z proj` 直接跳過去 |
| `ripgrep` | 檔案內容搜尋 | `grep` | 快很多，預設尊重 `.gitignore` |
| `fd-find` | 檔名搜尋 | `find` | 語法人性化很多 |
| `bat` | 檔案檢視 | `cat` | 語法高亮 + 行號 + 分頁 |
| `shellcheck` | shell 腳本檢查 | — | 寫 bash 時即時抓錯，比讀教材有效 |

### zsh 框架與 plugin（`git clone`）

這些是**別人的 repo**，所以裝在 `~/.oh-my-zsh/` 底下，不進這個 dotfiles repo。
界線：別人的程式碼在 `~/.oh-my-zsh/`，我的設定在 `~/dotfiles/`。

| 項目 | 來源 | 作用 |
|---|---|---|
| `oh-my-zsh` | ohmyzsh/ohmyzsh | zsh 設定框架，提供 plugin 與主題機制 |
| `powerlevel10k` | romkatv/powerlevel10k | 提示字元主題。顯示分支、狀態、執行時間 |
| `zsh-autosuggestions` | zsh-users/… | **打字時根據歷史顯示灰字建議，按 `→` 接受** |
| `zsh-syntax-highlighting` | zsh-users/… | 指令打對綠色、打錯紅色，**送出前就知道** |

> `zsh-syntax-highlighting` 必須是 plugin 清單的**最後一個**，否則它抓不到後面才註冊的指令。

### Debian 系的改名問題

Ubuntu / Debian 把兩個工具改了名字（避免與既有套件衝突）：

| 你以為的指令 | 實際安裝的名字 |
|---|---|
| `fd` | `fdfind` |
| `bat` | `batcat` |

`bootstrap.sh` 會在 `~/.local/bin/` 建立符號連結，讓你能用大家熟悉的名字。
**這是 Ubuntu 特有的坑**，在 macOS 或 Arch 上不會遇到。

---

## 這些工具怎麼用

### fzf —— 這是「快速 navigate terminal」的答案

裝好之後多出三組鍵位（不需要記指令）：

| 按鍵 | 作用 |
|---|---|
| **`Ctrl-R`** | 模糊搜尋**歷史指令**。打 `dock com` 就找出 `docker compose up -d --build` |
| **`Ctrl-T`** | 模糊搜尋**檔案路徑**，選中後插入到目前的指令列 |
| **`Alt-C`** | 模糊搜尋**目錄**並直接 `cd` 過去 |

模糊的意思是**字元順序對就好，不用連續**。搜 `dcub` 也能找到 `docker compose up --build`。

也能接在管線後面當選單：

```bash
git branch | fzf              # 用選的切分支
kill -9 $(ps aux | fzf | awk '{print $2}')
```

> 這就是為什麼歷史紀錄設成 50000 筆（`zsh/custom/10-history.zsh`）——
> `Ctrl-R` 的價值完全取決於歷史夠不夠長。

### zoxide —— 不用再打長路徑

它記住你去過哪些目錄與去的頻率：

```bash
$ cd ~/ubuntu-project/MITOpenCourse/tracks/1-systems    # 正常去一次
$ cd ~
$ z systems      # 之後直接跳，不用打完整路徑
$ z MIT          # 部分比對也可以
$ zi             # 互動選單（配合 fzf）
```

**用越多次的目錄排名越前面**，所以用久了幾乎都是一次命中。

### ripgrep（`rg`）—— 取代 grep

```bash
$ rg "TODO"                  # 遞迴搜整個目錄，自動跳過 .gitignore 的檔案
$ rg "func.*Handler" -t go   # 只搜 .go 檔
$ rg "error" -A 3 -B 1       # 顯示命中行的前 1 行、後 3 行
$ rg -i "warning"            # 忽略大小寫
```

比 `grep -r` 快非常多，而且**預設就不會搜 `node_modules` 和 `.git`**。

### fd —— 取代 find

```bash
# find 的寫法
$ find . -name "*.md" -type f

# fd 的寫法
$ fd -e md
```

```bash
$ fd config                  # 檔名含 config 的
$ fd -e ts -e tsx            # 副檔名是 ts 或 tsx
$ fd -H secret               # 含隱藏檔（預設跳過）
```

### bat —— 取代 cat

```bash
$ bat script.sh              # 語法高亮 + 行號
$ bat -p file.txt            # 純輸出，不加裝飾（適合接管線）
$ rg "TODO" -l | xargs bat   # 搭配使用
```

### shellcheck —— 寫 bash 的安全網

```bash
$ shellcheck install.sh
```

它會抓出**引號漏了、變數沒引、`[ ]` 與 `[[ ]]` 用錯**這類經典問題。
建議裝進編輯器外掛，寫的時候就即時畫紅線 —— 這比讀任何 bash 教材都有效。

---

## 疑難排解

| 症狀 | 原因 | 解法 |
|---|---|---|
| `fatal: user.email is not set` | `~/.gitconfig.local` 沒填 | 填它。這是刻意的防線，不是 bug |
| `[oh-my-zsh] plugin 'xxx' not found` | 不該發生 —— `.zshrc` 會跳過不存在的 plugin | 若真的出現，檢查 `.zshrc` 的 plugin 判斷段落 |
| `Ctrl-R` 沒有模糊搜尋 | fzf 沒裝 | 跑 `./bootstrap.sh` |
| 沒有灰字歷史建議 | `zsh-autosuggestions` 沒裝 | 跑 `./bootstrap.sh` |
| 改了設定沒生效 | shell 沒重載 | `reload`（= `exec zsh`） |
| 顏色顯示不正常 | 終端機的 `TERM` 宣告問題 | 先確認 `echo $TERM` 與 `$COLORTERM`，不要直接硬設 `TERM` |
| 想暫時停用某段設定 | — | 檔名加 `.off`，例如 `20-aliases.zsh.off`，然後 `reload` |

---

## 只要 git alias（公司機器適用）

不想裝整套、或沒有權限時，**只複製一個檔案就能用**：

```bash
scp ~/dotfiles/shell/git-aliases.sh 目標機器:~/
echo 'source ~/git-aliases.sh' >> ~/.zshrc    # 必須加在最後面
exec zsh
```

那個檔案自足、零相依、bash 與 zsh 都能用。
詳細說明見 [`shell/README.md`](shell/README.md)。

---

## 結構

```
~/dotfiles/
├── bootstrap.sh              新機器：裝套件、clone omz 與 plugin、產生身分範本
├── install.sh                建立符號連結（-n 可乾跑）
├── MANIFEST.md               ★ 每個檔案是什麼、為什麼、以及「刻意不做什麼」
├── git/
│   └── .gitconfig            → ~/.gitconfig  （純行為，不含身分）
├── shell/
│   ├── git-aliases.sh        ★ 可攜的 git alias，複製到任何機器都能用
│   └── README.md             git alias 使用手冊（按情境查，附操作範例）
└── zsh/
    ├── .zshrc                → ~/.zshrc      （只放載入邏輯）
    ├── .p10k.zsh             → ~/.p10k.zsh   （powerlevel10k 外觀）
    ├── custom/               ★ 實際設定在這裡，依編號順序自動載入
    │   ├── 00-exports.zsh    PATH、EDITOR
    │   ├── 10-history.zsh    歷史紀錄
    │   ├── 20-aliases.zsh    alias
    │   ├── 30-functions.zsh  函式
    │   └── 40-git.zsh        載入 shell/git-aliases.sh
    └── reference/
        └── omz-template.zsh  oh-my-zsh 原始樣板存檔，純備查
```

---

## 日常使用

| 想做什麼 | 怎麼做 |
|---|---|
| 加一個 alias | 編輯 `zsh/custom/20-aliases.zsh`，然後 `reload` |
| 加一個函式 | 編輯 `zsh/custom/30-functions.zsh` |
| 加一整類新設定 | 新增 `zsh/custom/50-xxx.zsh`（編號要補零） |
| 改 git 行為 | 編輯 `git/.gitconfig` |
| 改 git 身分 | 編輯 `~/.gitconfig.local`（**不在這個 repo**） |
| 暫時停用某段設定 | 把檔案改名加 `.off`，例如 `20-aliases.zsh.off` |
| 重新載入 | `reload`（= `exec zsh`） |

**不需要重跑 `install.sh`** —— 因為是符號連結，你改 repo 裡的檔案就是改生效中的設定。

---

## 設計原則

這些原則的完整理由寫在 [`MANIFEST.md`](MANIFEST.md)。

1. **符號連結，不是複製。**
   複製法需要你「記得」同步，而沒有人會記得。上一版 dotfiles 用 `cp` 備份，
   結果 repo 停在 2023 年，機器一路往前，兩邊安靜分岔了兩年。

2. **這個 repo 放「行為」，不放「身分」。**
   alias、diff 演算法換機器不會變 → 版控。
   email、SSH 金鑰會隨環境改變 → `~/.gitconfig.local`，不版控。

3. **別人的程式碼不進來。**
   oh-my-zsh、powerlevel10k、plugin 都由 `bootstrap.sh` 取得，
   界線是：別人的程式碼在 `~/.oh-my-zsh/`，我的設定在 `~/dotfiles/`。

4. **短 alias 只給唯讀操作。**
   有副作用的名稱寫清楚（`gpush` 而非 `gp`），破壞性的不做 alias。

5. **大聲失敗優於安靜做錯。**
   只「新增」名稱、不「覆蓋」既有名稱 —— 別台機器上得到 `command not found`
   遠好過靜默執行別的動作。

6. **不為還沒發生的問題蓋機制。**
   刻意沒做：`~/.zshrc.local` 分層、逐 repo 的 git 身分切換、GNU stow。
   真的需要那天再加，MANIFEST 記了做法。

---

## 復原

`install.sh` 會把被取代的原檔備份到 `~/.dotfiles-backup/<時間戳>/`。

要退回舊設定：

```bash
rm ~/.zshrc                                          # 移除符號連結
cp ~/.dotfiles-backup/20260815-174500/.zshrc ~/      # 放回原檔
exec zsh
```
