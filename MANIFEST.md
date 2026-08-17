# MANIFEST — 這裡放了什麼、為什麼

> 半年後你看到某行設定會想「這什麼鬼」。這份檔案就是為了那一刻。
> **每次加東西進 repo，順手在這裡補一行。**

---

## 核心原則：這個 repo 放「行為」，不放「身分」

這是這份設定最重要的一條分界線。

| | 是什麼 | 會隨環境改變嗎 | 放哪 |
|---|---|---|---|
| **行為** | alias、diff 演算法、衝突樣式、歷史長度 | ❌ 不會 | ✅ 這個 repo |
| **身分** | git name/email、SSH 金鑰、公司設定 | ✅ 會 | ❌ `~/.gitconfig.local`（不版控） |
| **機器專屬** | 只有某台機器才有的程式路徑 | ✅ 會 | ⚠️ 用存在性檢查守住，見下 |

**這個 repo 的目的是「我自己的工具資料庫」——它不該因為換電腦或換 email 就改變。**

### 身分怎麼處理

身分放 `~/.gitconfig.local`（不版控），由 `git/.gitconfig` 最下方的 `[include]` 載入。
`bootstrap.sh` 會在新機器上產生範本。

一台機器一個身分就夠：這台填個人 email，公司機器填公司 email。

`user.useConfigOnly = true` 是保險。它保護的正好是這個 repo 最在意的場景：
新機器 clone 完 dotfiles、跑完 `install.sh`、**忘了填 `.gitconfig.local`**，
然後開始用 `bc@DESKTOP-XYZ` 提交 —— 那個 email 會永久留在歷史裡。
有這行就會直接報錯：

```
fatal: user.email is not set and useConfigOnly is set
```

**沒有做逐 repo 身分切換**（`gitid` 函式、`includeIf` 條件設定）。
那是為「同一台機器要用兩個身分」設計的，目前沒這個需求 ——
為還沒發生的問題先蓋機制就是過早設計。

真的需要那天，`.gitconfig.local` 這個結構本來就支援 `includeIf`，加回來很容易：

```ini
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
```

> 順帶釐清一個常見混淆：**SSH 金鑰和 commit email 是兩回事。**
> 金鑰決定 push 時 GitHub 認你是哪個帳號，可以靠 `~/.ssh/config` 的 Host 別名分流多把；
> `user.email` 決定 commit 裡寫誰的名字，全域只有一個值。

### 機器專屬設定怎麼處理

**目前一個都沒有，這是刻意的。**

判斷標準很簡單：**這個設定換到別台機器還有意義嗎？** 沒有的話就不該進來。

（例：原本 `.zshrc` 有個 obsidian alias，那是為了繞過「WSL 裡的檔案 Windows 讀不到」
才另外裝的版本。其他機器上用的是桌面 App，這個 alias 毫無意義 —— 所以不收。）

將來真的有非收不可的機器專屬設定時，兩種做法：

```zsh
# 做法一：存在性檢查（只有一兩個時用這個，成本最低）
[[ -x "$HOME/some/binary" ]] && alias foo='...'
```

```zsh
# 做法二：拆出 ~/.zshrc.local 不版控（累積到五六個再考慮）
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

現在不做做法二 —— 為了零個設定先蓋一層抽象，是典型的過早設計。

## 檔案清單

| repo 內路徑 | symlink 到 | 是什麼 |
|---|---|---|
| `zsh/.zshrc` | `~/.zshrc` | zsh 啟動檔。**只放載入框架的邏輯**，短到一眼看得完 |
| `zsh/.p10k.zsh` | `~/.p10k.zsh` | powerlevel10k 外觀設定，91KB，由 `p10k configure` 產生 |
| `zsh/custom/*.zsh` | 不連結 | 你的實際設定，由 `.zshrc` 的迴圈依檔名順序 source |
| `zsh/reference/omz-template.zsh` | 不連結 | oh-my-zsh 原始樣板存檔，純備查 |
| `git/.gitconfig` | `~/.gitconfig` | git **行為**設定。每條都註解了「預設是什麼／改成什麼／不設會怎樣」 |
| — | `~/.gitconfig.local` | git **身分**設定。**不在這個 repo**，由 `bootstrap.sh` 產生範本 |
| `install.sh` | — | 建立符號連結。可無限次重跑 |
| `bootstrap.sh` | — | 新機器裝套件與 plugin。一台機器跑一次 |
| `work-install.sh` | — | 最小安裝：只在現有 `.zshrc` 尾端加一段標記區塊 |
| `shell/*.sh` | 不連結 | **可攜層**。自足、零相依、bash 與 zsh 都能用 |

## `shell/` 是可攜層 —— 為什麼要跟 `zsh/custom/` 分開

`zsh/custom/*.zsh` 綁在 `.zshrc` 的載入迴圈上，只有「完整安裝」的機器有。
但公司機器走的是「在現有 `.zshrc` 加一行」的模式，吃不到那個迴圈。

所以真正的設定內容放在 `shell/`，兩邊都只是薄薄一層 source：

```
zsh/custom/10-history.zsh    →  source shell/history.sh    ┐
zsh/custom/30-functions.zsh  →  source shell/functions.sh  ├→ 同一份來源
zsh/custom/40-git.zsh        →  source shell/git-aliases.sh│
zsh/custom/50-tools.zsh      →  source shell/tools.sh      ┘
shell/work-profile.sh        →  source 上面全部（公司機器的入口）
```

**關鍵是「同一份」**。如果兩邊各寫一份，改一次要記得改兩個地方 ——
而兩份一定會發散，發散之後肌肉記憶就失效了。
肌肉記憶只有在「每台機器都一樣」時才有價值。

| 檔案 | 內容 | shell |
|---|---|---|
| `git-aliases.sh` | 46 個 alias，並移除 13 個危險的 | bash + zsh |
| `git-audit.sh` | `git-audit` 函式 | bash + zsh |
| `functions.sh` | `mkcd`、`biggest` | bash + zsh |
| `history.sh` | 歷史長度與行為 | **zsh 專用**（對 bash 早退） |
| `tools.sh` | fzf 鍵位與設定、zoxide | bash + zsh |
| `work-profile.sh` | 公司機器入口，source 上面全部 | bash + zsh |

`shell/` 底下的檔案有一條額外規則：**只能新增指令，不能改掉既有指令的行為**
（`git-aliases.sh` 是唯一的例外，而那是刻意的，所以才需要 `-c` 檢查）。
理由是它們會被載進別人已經在用的機器。

## `zsh/custom/` 的檔名編號

數字前綴決定載入順序，這是有意義的：後面的檔案可以用到前面定義的東西。

| 檔案 | 內容 | 實際內容在哪 |
|---|---|---|
| `00-exports.zsh` | PATH、`EDITOR` 等環境變數。**最先載入**，後面全部依賴它 | 就在這裡（**不可攜** —— PATH 順序屬於機器） |
| `10-history.zsh` | 歷史紀錄長度與行為 | `shell/history.sh` |
| `20-aliases.zsh` | alias | 就在這裡（`dot`、`zshrc` 只對本機有意義） |
| `30-functions.zsh` | 需要參數處理或多行邏輯的函式 | `shell/functions.sh` |
| `40-git.zsh` | git alias 與 `git-audit` | `shell/git-aliases.sh`、`shell/git-audit.sh` |
| `50-tools.zsh` | fzf、zoxide 的 shell 整合 | `shell/tools.sh` |

要加新類別就沿用這個編號規則，例如 `60-docker.zsh`。

**新增設定時先問一句：這東西在一台「只有最小安裝」的機器上有意義嗎？**
有 → 寫進 `shell/`，這裡只留一行 source。
沒有（例如依賴 `~/dotfiles` 存在、或會改 PATH 順序）→ 才直接寫在這裡。

**編號一定要補零用固定寬度。** 字母排序下 `10-` 會排在 `2-` 前面，
用 `02-` `10-` 才不會出事。跳號跳 10 是為了留空間插隊（`05-` 之類）。

---

## 為什麼不放這些

| 東西 | 位置 | 理由 |
|---|---|---|
| `~/.oh-my-zsh/` | 別人的 repo | 1240 個檔案，clone 自 ohmyzsh/ohmyzsh。`bootstrap.sh` 負責裝 |
| `powerlevel10k` 主題 | `~/.oh-my-zsh/custom/themes/` | 同上，clone 自 romkatv/powerlevel10k |
| `zsh-autosuggestions` 等 plugin | `~/.oh-my-zsh/custom/plugins/` | 同上 |
| `~/.ssh/` 私鑰 | 哪裡都不放 | **絕對不能進版控。** 洩漏一次就全毀 |
| `~/.ssh/config` | 尚未建立 | 目前沒有常用的遠端主機。有需要再加 |
| `~/.tmux.conf` | 尚未建立 | tmux 裝了但沒設定過。Missing Semester S1 之後補 |

**界線原則：別人的程式碼在 `~/.oh-my-zsh/`，我的設定在 `~/dotfiles/`。**

---

## 幾個設定的理由

看起來莫名其妙但其實有原因的，記在這裡。

### `.zshrc` 為什麼幾乎是空的

原本的 `~/.zshrc` 有 119 行，其中 111 行是 oh-my-zsh 安裝時產生的註解樣板
（`# Uncomment the following line to...`），實際生效的設定只有 7 行，被埋在最底下。

清乾淨之後，你才看得見自己到底設了什麼。原始樣板存在 `zsh/reference/` 備查。

### 為什麼不用 `ZSH_CUSTOM` 指向這個 repo

原本想用 oh-my-zsh 的 `$ZSH_CUSTOM` 機制自動載入。但那個變數同時決定 oh-my-zsh
去哪裡找 **plugin 和 theme** —— 一旦指向 dotfiles repo，別人的 repo 就得 clone 進來
（再 gitignore 掉），界線就髒了。

改用 `.zshrc` 裡一個明確的 `for` 迴圈 source，三行解決，而且看得懂。

### 為什麼不用 GNU stow

只有三個檔案要連結，stow 的自動化價值出不來，還多一個相依。
自己寫的 `install.sh` 每一行都看得懂 —— 這門課的目的本來就是搞懂底下在做什麼。
檔案多到三十個再換 stow 也不遲，那時已經懂原理了。

### `obs` 為什麼只剩一個縮放值

原本 `.zshrc` 裡 `alias obs=` 被定義了兩次（1.5 和 1.8），後者覆蓋前者，
第一行是永遠不會生效的死碼。已統一為 1.8。

### `rerere.enabled` 是什麼

REuse REcorded REsolution。git 會記住你怎麼解某個衝突，下次遇到一模一樣的自動套用。

rebase 一長串 commit 時，同一個衝突可能重複出現五次 —— 開了這個只需要解一次。
這是「rebase 很痛」最主要的來源之一。

### `HIST_IGNORE_SPACE` 有什麼用

以空白字元開頭的指令不會被記進歷史。打含密碼或 token 的指令時，
前面加一個空白就不會留下痕跡。

---

## 備份策略

**目前純本地，沒有遠端。**

WSL2 環境下最可能發生的「換機器」事件是**發行版重建**，而那時 Windows 側是完好的。
所以不需要 GitHub 帳號也能有備援：

```bash
git init --bare /mnt/c/Users/<帳號>/dotfiles.git
git remote add origin /mnt/c/Users/<帳號>/dotfiles.git
git push -u origin main
```

- [ ] 尚未設定
