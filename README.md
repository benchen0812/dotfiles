# dotfiles

我的 shell 與 git 環境設定。

**這個 repo 是「跨機器的工具庫」，不是這台機器的設定備份。**
所以它只放不隨環境改變的東西 —— 身分（email）、機器專屬路徑都不在這裡。

[**Cheat Sheet**](#cheat-sheet) ·
[安裝](#兩種安裝情境) ·
[結構](#結構) ·
[驗證](#安裝後驗證) ·
[疑難排解](#疑難排解)

---

# Cheat Sheet

> `★` = 最值得先記的。
> 「什麼時候用、為什麼這樣命名」的完整說明在
> [`shell/README.md`](shell/README.md)（按情境查，附操作範例）；
> 終端機工具看 [`shell/TOOLS.md`](shell/TOOLS.md)。

## 鍵位 —— 不用記指令，最高投報率

| 鍵 | 做什麼 | 來自 |
|---|---|---|
| `Ctrl-R` | ★ 模糊搜尋**歷史指令**。不要再按上鍵翻 | fzf |
| `Ctrl-T` | 模糊搜尋**檔案**，選中的路徑插入到游標位置 | fzf |
| `Alt-C` | 模糊搜尋**目錄**並 `cd` 過去（macOS 要先設 Option 鍵） | fzf |
| `→` | 接受灰字歷史建議（整行） | zsh-autosuggestions |
| `Ctrl-→` | 只接受建議的下一個字 | zsh-autosuggestions |

## git —— 唯讀（零風險，打錯了沒後果）

### 狀態與差異

| alias | 展開 | 說明 |
|---|---|---|
| `g` | `git` | |
| `gst` | `git status` | 完整狀態，含提示文字 |
| `gss` | `git status --short` | ★ 精簡：兩欄符號 + 檔名 |
| `gsb` | `git status --short --branch` | 精簡 + 分支與領先/落後 |
| `gd` | `git diff` | 改了但**還沒 add** 的 |
| `gds` | `git diff --staged` | ★ 已 add、要提交的 |
| `gdw` | `git diff --word-diff` | 逐「字」比對，改文件時好讀很多 |

### 歷史與追溯

| alias | 展開 | 說明 |
|---|---|---|
| `glo` | `git log --oneline --decorate` | |
| `glog` | `git log --oneline --decorate --graph` | ★ 帶分支線 |
| `glol` | `git log --graph --pretty=…` | 彩色、含作者與相對時間 |
| `glg` | `git log --stat` | 每個 commit 附「哪些檔案改了幾行」 |
| `gbl` | `git blame -w` | 每一行是誰改的（`-w` 忽略純空白改動） |
| `grl` | `git reflog` | ★★ HEAD 移動的完整歷史 —— **出事時的第一站** |

### 分支與遠端

| alias | 展開 | 說明 |
|---|---|---|
| `gb` | `git branch` | 本地分支 |
| `gba` | `git branch --all` | 含遠端分支 |
| `gbv` | `git branch -vv` | ★ 每個分支「追蹤誰」「領先/落後幾個」 |
| `gf` | `git fetch` | 只抓遠端更新，不動工作目錄。**永遠安全** |
| `grv` | `git remote -v` | remote 指向哪些 URL |

### stash

| alias | 展開 | 說明 |
|---|---|---|
| `gstl` | `git stash list` | 有哪些 stash |
| `gsts` | `git stash show -p` | 看最上面那個的內容 |

## git —— 日常

| alias | 展開 | 說明 |
|---|---|---|
| `ga` | `git add` | |
| `gaa` | `git add --all` | 所有變更，含新檔案與刪除 |
| `gapa` | `git add --patch` | ★ 逐「區塊」挑要提交的部分 |
| `gc` | `git commit --verbose` | ★ 編輯器裡會一起顯示 diff |
| `gcmsg` | `git commit -m` | 一行訊息，不開編輯器 |
| `gcam` | `git commit -a -m` | `-a` 只含**已追蹤**檔案，新檔案不會進去 |
| `gac` | `git add --all && git commit -m` | 含新檔案。跟 `gcam` 的差別見下 |
| `gco` | `git checkout` | 切分支（也能還原檔案 —— 一詞多義是 git 的設計失誤） |
| `gcb` | `git checkout -b` | 建立並切換到新分支 |
| `gcm` | `git checkout <主分支>` | 自動判斷 main 還是 master |
| `gbd` | `git branch --delete` | 安全刪除：未合併的會被擋 |

> **`gcam` vs `gac`**：`gcam` 的 `-a` 只暫存**已追蹤**檔案 ——
> 新增的檔案不會被提交，而且不會有任何提示。`gac` 用 `--all`，包含新檔案。
> 這是最容易踩到的一個差異。

## git —— 有副作用（名稱刻意寫長，讓手指慢下來）

| alias | 展開 | 說明 |
|---|---|---|
| `gpush` | `git push` | |
| `gpushu` | `git push -u origin HEAD` | ★ 新分支第一次推，順便建立追蹤 |
| `gpull` | `git pull` | 預設是 fetch + merge |
| `gpullr` | `git pull --rebase` | |
| `gamend` | `git commit --amend --no-edit` | 改上一個 commit 的內容，不改訊息 |
| `gsta` | `git stash push` | 收起修改，工作目錄回到乾淨 |
| `gstp` | `git stash pop` | 取回並從清單移除 |

## git —— Rebase / Merge

| alias | 展開 | 說明 |
|---|---|---|
| `grb` | `git rebase` | |
| `grbi` | `git rebase --interactive` | ★ 整理歷史（squash / reword / drop） |
| `grbc` | `git rebase --continue` | 解完衝突後繼續 |
| `grba` | `git rebase --abort` | ★★ **完全放棄，回到 rebase 前**。救命用 |
| `grbom` | `git rebase origin/<主分支>` | 把分支更新到主分支最新狀態 |
| `gm` | `git merge` | |
| `gmc` | `git merge --continue` | |
| `gma` | `git merge --abort` | ★★ 同樣是救命用 |

## 被移除的 13 個（打了會 `command not found`）

**大聲失敗永遠比安靜做錯好。** 判斷標準：git 靠 reflog 幾乎能救回所有
**commit 過**的東西，救不回的只有**沒 commit 過的變更** ——
所有攻擊那個部分的指令都算危險。

| 移除 | 原本是 | 要用就完整打 / 改用 |
|---|---|---|
| `gwipe` | `git reset --hard && git clean -df` | 完整打 |
| `gpristine` | `git reset --hard && git clean -dfx` | 完整打 |
| `gclean` | `git clean --interactive -d` | 完整打 |
| `grhh` | `git reset --hard` | 完整打 |
| `grs` | `git restore` | 完整打 |
| `grss` | `git restore --source` | 完整打 |
| `gstc` | `git stash clear` | 完整打（最陰險的一個：一次刪光所有 stash） |
| `gstd` | `git stash drop` | 完整打 |
| `gpf!` | `git push --force` | 用 `--force-with-lease` |
| `gbD` | `git branch -D` | 完整打 |
| `grbs` | `git rebase --skip` | 完整打 |
| `gp` | `git push` | **`gpush`** |
| `gl` | `git pull` | **`gpull`** |

`gp` / `gl` 不是破壞性的，移除是為了換掉舊習慣 ——
`gl` 緊鄰 `glo` / `glog` / `glg`（都是 log），少打一個字母就從「看歷史」變成「拉取」。

## git 內建 alias —— 跨 shell、跨 OS

這些寫在 `git/.gitconfig` 的 `[alias]` 段，是 **git 自己讀的**，
所以在 bash、fish、甚至 Windows 的 PowerShell 裡都一樣能用。
代價是要多打 `git ` 四個字元。

| 指令 | 展開 |
|---|---|
| `git st` | `status --short --branch` |
| `git lg` | `log --graph --oneline --decorate --all` |
| `git last` | `log -1 --stat` |
| `git unstage` | `restore --staged`（移出暫存區，保留修改） |
| `git amend` | `commit --amend --no-edit` |
| `git undo` | `reset --soft HEAD~1`（撤銷 commit，變更留在暫存區） |
| `git filelog` | `log --follow -p --`（單一檔案的完整歷史，跨改名） |
| `git branches` | `branch -vv --sort=-committerdate` |

> ⚠️ **最小安裝（公司機器）拿不到這一組** —— 它們在 `.gitconfig` 裡，
> 而最小安裝不碰那個檔案。見[兩個已知缺口](#兩個已知缺口)。

## 非 git

| 指令 | 做什麼 | 最小安裝有嗎 |
|---|---|---|
| `git-audit` | ★ 機器消失前，找出只存在本機的工作 | ✅ |
| `mkcd <dir>` | 建立目錄後直接進去 | ✅ |
| `biggest [n]` | 目前目錄底下最大的 N 個檔案（預設 10） | ✅ |
| `z <關鍵字>` | ★ 跳到常去的目錄（靠頻率 × 最近使用排名） | ✅ 需裝 zoxide |
| `zi` | 互動選單挑目錄 | ✅ 需裝 zoxide |
| `z -` | 回上一個目錄 | ✅ 需裝 zoxide |
| `rg <字串>` | 搜檔案**內容**，取代 `grep -r` | ✅ 需裝 ripgrep |
| `fd <檔名>` | 搜**檔名**，取代 `find` | ✅ 需裝 fd |
| `bat <檔案>` | 語法高亮 + 行號，取代 `cat` | ✅ 需裝 bat |
| `dot` | `cd ~/dotfiles` | ❌ 完整安裝才有 |
| `zshrc` | 編輯 `~/dotfiles/zsh/.zshrc` | ❌ 完整安裝才有 |
| `reload` | `exec zsh`（完整重跑啟動流程） | ❌ 直接打 `exec zsh` |

---

# 兩種安裝情境

| | 情境一：完整安裝 | 情境二：最小安裝 |
|---|---|---|
| **適用** | 你自己的機器、全新環境 | **公司機器**、不想動現有設定 |
| **會做什麼** | 取代 `.zshrc` / `.gitconfig`（符號連結）、裝套件 | **只在現有 `.zshrc` 加一行** |
| **動到哪些檔案** | `.zshrc`、`.gitconfig`、`.p10k.zsh`（原檔備份） | **只有 `.zshrc` 尾端加一段標記區塊** |
| **需要 sudo** | 要 | 不用 |
| **裝套件嗎** | 會（apt / brew） | **不會，工具要自己裝** |
| **怎麼移除** | 從備份還原 | **`./work-install.sh -u`** |
| **拿到什麼** | 全部 | git alias、`git-audit`、`mkcd`/`biggest`、歷史設定、fzf 鍵位、`z` |

> 「只動一個檔案」不等於「什麼都沒變」——
> alias 的意義會變，這是刻意的（那正是換掉舊習慣的機制）。
> 完整的影響清單見[情境二](#情境二公司機器最小安裝)。

---

## 情境一：完整安裝（你自己的機器）

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
  已備份 .zshrc → ~/.dotfiles-backup/20260815-195529/
  已連結 ~/.zshrc → ~/dotfiles/zsh/.zshrc
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

## 情境二：公司機器（最小安裝）

**適用時機**：那台機器已經有你自己的 `.zshrc`，可能很亂但能跑，
而你現在沒時間整理，也不想在忙的時候搞壞能用的環境。

### 安裝

```bash
# 1. 拿到 repo
git clone https://github.com/benchen0812/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. 裝工具（可選，但 fzf 是這裡最有價值的東西）
#    這一步 work-install.sh 不會幫你做 —— 它刻意不裝任何套件。
#    macOS：
brew install fzf fd bat zoxide
#    ⚠️ brew 裝完 fzf 會提示你跑 $(brew --prefix)/opt/fzf/install —— 不要跑。
#       那支腳本會改你的 .zshrc。鍵位由 shell/tools.sh 負責綁。

# 3. 檢查碰撞（★ 唯一需要你做判斷的一步）
./work-install.sh -c     # 會跟你現有的 alias / 函式 / 指令撞到什麼

# 4. 安裝
./work-install.sh -n     # 乾跑：只顯示會做什麼，不動任何檔案
./work-install.sh        # 實際安裝（會先備份 .zshrc）
exec zsh                 # 生效

# 5. 驗證 → 見「最小安裝的驗證」，最容易漏的是 fzf 鍵位
bindkey '^R'             # 應顯示 fzf-history-widget
```

**第 3 步看到 🔴 就先停下來。** 那些名字之後會做不同的事，而且不會報錯 ——
這是整個流程唯一有機會造成困擾的地方。要保留舊習慣的，
裝完在 `.zshrc` 的 source 那行**之後**再定義一次即可（後執行的贏）。
🟡 和 🟠 通常都是「（無）」。

**第 2 步跳過也能裝** —— `shell/tools.sh` 全程用 `command -v` 守著，
沒裝的工具就靜默跳過。之後任何時間補裝，下次開終端機自動生效，
不用再改任何設定。`Ctrl-R` 搜歷史連一個外部工具都不需要。

完整驗證清單見 [最小安裝的驗證](#最小安裝的驗證公司機器)；
`Alt-C` 在 macOS 上要先設 Option 鍵，見 [macOS 額外注意](#macos-額外注意)。

### 實際會影響什麼

| 類別 | 行為 | 風險 |
|---|---|---|
| **git alias** | 46 個新增、13 個移除。**名字撞到的會改變意義** | 🔴 見下面的 `-c` 檢查 |
| `mkcd` / `biggest` / `git-audit` | 純新增函式 | 撞名才有影響，`-c` 會報 |
| `HISTSIZE` / `SAVEHIST` | 調到 50000，但**只升不降** —— 已經設更大的不動 | 無，不會損失歷史 |
| `HISTFILE` | **只在該機器沒設過時才設** | 無 |
| 7 個 history `setopt` | 無條件設定。改變「之後怎麼記錄與搜尋」 | 低，不刪既有歷史 |
| `FZF_*` 環境變數 | **只在該機器沒設過時才設** | 無 |
| fzf 鍵位 `Ctrl-R`/`Ctrl-T`/`Alt-C` | 該機器沒綁過才綁（已有 omz fzf plugin 就不動） | 低 |
| `z` / `zi` | zoxide 佔用，`-c` 會檢查撞名 | 撞名才有影響 |
| **PATH** | **完全不動** | 無 |
| `.gitconfig` / `.p10k.zsh` | **完全不動** | 無 |

不想要其中某一項，在 `.zshrc` 的 source 那行**之後**覆蓋回去就行 ——
後執行的贏。例如不習慣多視窗共享歷史：

```zsh
unsetopt SHARE_HISTORY
```

### macOS 額外注意

- **`Alt-C` 預設是死的。** Option 鍵要先對應到 Meta：
  iTerm2 把 Left Option 設成 `Esc+`；Terminal.app 勾「Use Option as Meta key」。
  `Ctrl-R` 和 `Ctrl-T` 不受影響。
- 沒有 brew 也不能 sudo 時，fzf 可以完全裝在家目錄：
  ```bash
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --key-bindings --completion --no-update-rc
  ```
  `--no-update-rc` 保證它不改你的設定檔。但執行檔會在 `~/.fzf/bin`，
  而我們刻意不動 PATH —— 所以這條路你要自己把它加進 PATH。

### ⚠️ 先跑 `-c` 檢查碰撞

**你現有的 alias 不需要清掉** —— 我們的區塊加在最後，只有「名字撞到」的才受影響。
但有一種情況會**靜默改變行為**，那是唯一需要注意的：

```
$ ./work-install.sh -c

會被「覆蓋成不同意義」的（最需要注意）
  🔴 gc       現在: git checkout    → 之後: git commit --verbose

會被移除的（打了會 command not found）
  🟡 gp       現在: git push

新增的函式撞到既有名字
  🟠 mkcd     現在: /usr/local/bin/mkcd

外部工具會佔用的短名（zoxide）
  🟠 z        現在: /Users/你/bin/z
```

| 分級 | 意思 | 風險 |
|---|---|---|
| 🔴 | 名字保留，但**做不同的事** | **高** —— 不會報錯，你會以為它還是舊行為 |
| 🟡 | 名字消失 | 低 —— `command not found`，大聲失敗 |
| 🟠 | 我們新增的東西蓋掉同名的既有指令 | 中 —— 通常是「（無）」 |

`-c` 檢查的範圍是 `work-profile.sh` 會載入的**所有**檔案，包含 alias、
`unalias`、函式，以及 zoxide 自己產生的 `z`/`zi`。
它也會自動排除「你自己那份 dotfiles」—— 在已經完整安裝的機器上跑不會自己撞自己。

不想改變某個 🔴 的話，在 `.zshrc` 的 source 那行**之後**再定義一次：

```zsh
# >>> dotfiles work-profile >>>
[ -f ".../work-profile.sh" ] && source "..."
# <<< dotfiles work-profile <<<

alias gc='git checkout'    # 保留我原本的習慣
```

移除：

```bash
cd ~/dotfiles && ./work-install.sh -u
```

### `work-install.sh` 做了什麼

它在你現有的 `.zshrc`（或 `.bashrc`）**最後**加一個標記區塊：

```zsh
# >>> dotfiles work-profile >>>
[ -f "/Users/你/dotfiles/shell/work-profile.sh" ] && source "..."
# <<< dotfiles work-profile <<<
```

**為什麼要用腳本而不是手打 `echo >> ~/.zshrc`：**

| 風險 | 腳本怎麼處理 |
|---|---|
| `>>` 打成 `>` → **整個 `.zshrc` 被清空** | 不會有這個機會 |
| 重複執行 → 加兩次 source | 偵測標記，已安裝就不做事 |
| 移除時要手動找到那行刪掉 | `-u` 一鍵移除，用標記精準定位 |
| 改壞了想還原 | 每次修改前自動備份成 `.zshrc.bak.<時間戳>` |

`.zshrc` / `.bashrc` 由 `$SHELL` 自動判斷，不用你指定。

**一定要加在最後面** —— 才蓋得過前面 oh-my-zsh 的定義（後定義的贏）。
`[ -f ... ] &&` 是保險：檔案不在時靜默跳過，不會噴錯。

### 它做什麼、不做什麼

| ✅ 會做 | ❌ 不會做 |
|---|---|
| 載入 46 個 git alias | 碰 `~/.gitconfig`（**公司身分在裡面**） |
| 移除 13 個危險 alias | 碰 `~/.p10k.zsh` |
| 載入 `git-audit`、`mkcd`、`biggest` | 碰 `PATH`（公司可能有自己包的 toolchain wrapper） |
| 設歷史長度與行為（`HISTFILE` 不覆蓋） | 建任何符號連結 |
| 綁 fzf 鍵位、載入 `z` | 裝任何套件（工具要自己 `brew install`） |

唯一被修改的檔案是 `~/.zshrc`，而且只在尾端加一段標記區塊 ——
`-u` 可以精準移除，`.zshrc` 會回到位元組層級的原狀。

### 兩個已知缺口

都是「不碰 `~/.gitconfig`」與「不假設 `~/dotfiles` 存在」的必然結果：

| 缺什麼 | 為什麼 |
|---|---|
| `git st`、`git lg`、`git undo` 那 9 個 | 它們在 `git/.gitconfig` 的 `[alias]` 段，而最小安裝不碰那個檔案 —— 公司的 git 身分在裡面 |
| `reload`、`dot`、`zshrc` | 在 `zsh/custom/20-aliases.zsh`，那些 alias 依賴 `~/dotfiles` 的路徑結構，只對完整安裝有意義 |

第一個如果在公司也想要，可以之後把 `[alias]` 段拆成獨立檔案，
在公司機器的 `~/.gitconfig` 加一行 `[include]` 引用它 ——
那一層是 **git 自己讀的，跨 shell、跨 OS 完全一樣**，
連原生 Windows 的 PowerShell 都通。目前沒做，要用再說。

`reload` 的替代就是直接打 `exec zsh`。

### ⚠️ `gp` 和 `gl` 會消失

`git-aliases.sh` 移除的 13 個裡面，有兩個不是破壞性的：

| 移除 | 原本是 | 改用 |
|---|---|---|
| `gp` | `git push` | `gpush` |
| `gl` | `git pull` | `gpull` |

移除 `gl` 是因為它緊鄰 `glo` / `glog` / `glg`（都是 log），少打一個字母
就從「看歷史」變成「拉取」。

**如果換習慣正是你的目的，這是刻意的機制。**
不想改的話，在 `work-profile.sh` 的 source 之後補回來：

```zsh
alias gp='git push'
alias gl='git pull'
```

### fzf 就在最小安裝裡，但執行檔要自己裝

`work-profile.sh` **不裝任何套件**，所以你要自己把執行檔弄起來：

```bash
brew install fzf fd bat zoxide              # macOS
sudo apt install fzf fd-find bat zoxide     # Debian / Ubuntu（需要權限）
```

鍵位不用你管 —— `shell/tools.sh` 會自己綁。

**為什麼要自己綁，不能靠 oh-my-zsh 的 fzf plugin：**

最小安裝那一行加在 `.zshrc` 的**最後**，而那個時間點 omz 早就跑完了，
加不了 plugin。如果 `tools.sh` 只設 `FZF_*` 環境變數，
`Ctrl-R` / `Ctrl-T` / `Alt-C` 一個都不會動 ——
因為根本沒有人去註冊那些 ZLE widget。

**「裝了 fzf」和「fzf 的鍵位活著」是兩件事。**

`tools.sh` 依序探測六個位置，第一個命中的就用：

```
1. fzf --zsh                        fzf ≥ 0.48 自己吐出整套（含補完）
2. ~/.fzf/shell/                    git clone 裝法
3. /opt/homebrew/opt/fzf/shell/     Mac，Apple Silicon
4. /usr/local/opt/fzf/shell/        Mac，Intel
5. /usr/share/doc/fzf/examples/     Debian / Ubuntu
6. /usr/share/fzf/                  Arch 等
```

如果該機器**已經有** omz 的 fzf plugin 綁好了，`tools.sh` 會偵測到
（查 `fzf-history-widget` 這個函式在不在）而跳過，不去動人家的綁定。

沒裝 fd / bat / zoxide 的機器會靜默跳過（每一項都用 `command -v` 守住），
所以先只裝 fzf 也完全沒問題 —— **`Ctrl-R` 搜歷史一個外部工具都不需要**，
而那是三個鍵位裡最常用的。

fzf 完整用法見 [`shell/TOOLS.md`](shell/TOOLS.md)。

### 為什麼這個 repo 是公開的

公開的好處很直接：**HTTPS clone 不需要任何認證**，
不用登入、不用金鑰、不用 token，公司帳號完全不會出現在任何地方。

推送仍然需要 collaborator 權限，所以公司機器**推不回來** —— 這是刻意的。
所有修改都在你自己的機器上做，公司那邊只消費，之後 `git pull` 取得更新。

#### 為什麼公開是安全的

因為這個 repo 的架構**從一開始就把身分排除在外**（見「設計原則」第 2 條）：

| | 在哪 |
|---|---|
| git email、SSH 金鑰 | `~/.gitconfig.local`、`~/.ssh/` —— **不在 repo 裡** |
| 機器專屬路徑 | 一個都沒有（刻意的） |
| token、密碼 | 沒有 |

當初為了「乾淨」做的設計，讓「可以公開」變成免費的附帶結果。
如果那時把 email 寫進 `git/.gitconfig`，現在就得先清 git 歷史才能公開。

> 公開 dotfiles 是社群常態 —— 大多數人的 dotfiles repo 都是公開的，
> 因為裡面本來就不該有秘密。

#### 如果之後改回 private

那時公司機器就需要認證。**用 Deploy Key**：綁在單一 repo、預設唯讀、
不牽涉任何 GitHub 帳號。

```bash
# 1. 在公司機器產生專用金鑰
ssh-keygen -t ed25519 -f ~/.ssh/dotfiles_deploy -N ""
cat ~/.ssh/dotfiles_deploy.pub

# 2. 貼到 https://github.com/<你>/dotfiles/settings/keys
#    → Add deploy key，不要勾 "Allow write access"

# 3. ~/.ssh/config 加別名
#      Host github-dotfiles
#          HostName github.com
#          User git
#          IdentityFile ~/.ssh/dotfiles_deploy
#          IdentitiesOnly yes      ← 沒這行 ssh 會試遍所有金鑰，可能誤用公司的

# 4. clone（主機名用別名，不是 github.com）
git clone git@github-dotfiles:benchen0812/dotfiles.git ~/dotfiles
```

---

## `git-audit` —— 機器消失前的檢查

**重灌、換機器、砍掉 WSL 發行版之前，先跑這個。**

```bash
$ git-audit                # 掃描家目錄
$ git-audit ~/projects     # 掃描指定目錄
```

```
~/ubuntu-project/cat-history
  ✗ 分支 master：領先 origin/master 9 個 commit（未推送）

~/ubuntu-project/investment-advisor
  ✗ 分支 feature/phase1-db：無 upstream，本地 5 個 commit
  ✗ 2 個未提交的變更

─────────────────────────────────────────
⚠  4 個 repo 有風險
   15 個 commit 只存在這台機器
   5 個未提交的檔案
```

### 為什麼需要工具，不能靠手動看

**手動檢查會漏，而且是系統性地漏 —— 你只會看當前分支。**

`git status` 顯示乾淨、當前分支也跟遠端同步，看起來完全安全。
但另一條 feature 分支上可能有五個 commit 從來沒推過，那條分支你根本沒切過去看。

這個工具逐一檢查**每一條分支**，加上未提交的變更與 stash。

> stash 特別危險：它**不在 reflog 裡**。commit 過的東西還能靠 reflog 救，
> stash 一旦隨機器消失就真的找不回來。

回傳值可以串進腳本：

```bash
git-audit && echo "確認安全，可以進行破壞性操作"
```

---

## 結構

```
~/dotfiles/
├── bootstrap.sh              新機器：裝套件、clone omz 與 plugin、產生身分範本
├── install.sh                建立符號連結（-n 可乾跑）
├── work-install.sh           最小安裝：只在現有 .zshrc 加一段（-n 乾跑 / -u 移除）
├── MANIFEST.md               ★ 每個檔案是什麼、為什麼、以及「刻意不做什麼」
├── git/
│   └── .gitconfig            → ~/.gitconfig  （純行為，不含身分）
├── shell/                    ★ 可攜層：自足、零相依，兩種安裝情境共用同一份
│   ├── git-aliases.sh        git alias（46 新增 / 13 移除）
│   ├── git-audit.sh          稽核工具，找出只存在本機的工作
│   ├── functions.sh          mkcd、biggest
│   ├── history.sh            歷史長度與行為（zsh 專用，對 bash 早退）
│   ├── tools.sh              fzf 鍵位與設定、zoxide
│   ├── work-profile.sh       ★ 公司機器入口：一行 source，載入上面全部
│   ├── README.md             git alias 使用手冊（按情境查，附操作範例）
│   └── TOOLS.md              終端機工具手冊（fzf / zoxide / rg / fd / bat）
└── zsh/
    ├── .zshrc                → ~/.zshrc      （只放載入邏輯）
    ├── .p10k.zsh             → ~/.p10k.zsh   （powerlevel10k 外觀）
    ├── custom/               依編號順序自動載入。多數只是一行 source shell/
    │   ├── 00-exports.zsh    PATH、EDITOR（不可攜：PATH 順序屬於機器）
    │   ├── 10-history.zsh    → shell/history.sh
    │   ├── 20-aliases.zsh    dot、zshrc、reload（不可攜：依賴 ~/dotfiles）
    │   ├── 30-functions.zsh  → shell/functions.sh
    │   ├── 40-git.zsh        → shell/git-aliases.sh、git-audit.sh
    │   └── 50-tools.zsh      → shell/tools.sh
    └── reference/
        └── omz-template.zsh  oh-my-zsh 原始樣板存檔，純備查
```

---

## 日常使用

| 想做什麼 | 怎麼做 |
|---|---|
| 加一個函式／設定，**想讓公司機器也吃到** | 編輯 `shell/` 底下對應的檔案 |
| 加一個只對這台機器有意義的 alias | 編輯 `zsh/custom/20-aliases.zsh`，然後 `reload` |
| 加一整類新設定 | 可攜的放 `shell/`，不可攜的新增 `zsh/custom/60-xxx.zsh`（編號補零） |
| 新增 `shell/` 檔案後 | ★ 記得同步更新 `work-profile.sh` 的 source 清單與 `work-install.sh` 的 `-c` 檢查清單 |
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

### 最小安裝的驗證（公司機器）

上面第 1、2、3、6 項不適用（沒有符號連結、不碰 `.gitconfig`）。改跑這些：

```bash
# 1. alias 載入了嗎
alias gpush gss

# 2. 危險的移除了嗎（應全部 command not found）
for a in gwipe gpristine grhh gp gl; do
  alias $a >/dev/null 2>&1 && echo "✗ $a 還在" || echo "✓ $a 已移除"
done

# 3. 函式載入了嗎（應顯示 function）
whence -w mkcd biggest git-audit

# 4. 歷史設定生效了嗎（應為 50000 或更大）
echo "$HISTSIZE / $SAVEHIST"

# 5. ★ fzf 鍵位活著嗎 —— 這是最容易「以為裝好了其實沒有」的一項
bindkey '^R'      # 應顯示 fzf-history-widget，不是 history-incremental-search-backward
bindkey '^T'      # 應顯示 fzf-file-widget
bindkey '\ec'     # 應顯示 fzf-cd-widget（macOS 見下方 Option 鍵注意事項）

# 6. fzf 用的是 fd 而不是 find 嗎
echo "$FZF_DEFAULT_COMMAND"

# 7. 冪等性（第二次應顯示「已經安裝過了」）
cd ~/dotfiles && ./work-install.sh
```

第 5 項如果 `^R` 顯示的不是 `fzf-history-widget`，順序這樣查：
`command -v fzf`（執行檔在不在）→ 在的話看 `tools.sh` 探測的六個路徑
哪個該中（`ls /opt/homebrew/opt/fzf/shell/`）。

**要真正確認可逆**，裝完先跑一次 `./work-install.sh -u` 再裝回來 ——
`.zshrc` 應該完全回到原狀（連結尾空行都一樣）。

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

> **完整手冊見 [`shell/TOOLS.md`](shell/TOOLS.md)** ——
> 含所有鍵位、fzf 的模糊搜尋語法、各工具的常用參數表、以及我們的設定選擇與理由。
> 下面只是速覽。

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

> 這就是為什麼歷史紀錄設成 50000 筆（`shell/history.sh`）——
> `Ctrl-R` 的價值完全取決於歷史夠不夠長。歷史是 fzf 的燃料。

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
