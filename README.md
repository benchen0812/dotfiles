# dotfiles

我的 shell 與 git 環境設定。

**這個 repo 是「跨機器的工具庫」，不是這台機器的設定備份。**
所以它只放不隨環境改變的東西 —— 身分（email）、機器專屬路徑都不在這裡。

---

## 在新機器上安裝

```bash
git clone <這個 repo> ~/dotfiles
cd ~/dotfiles

./bootstrap.sh      # 裝套件、clone oh-my-zsh 與 plugin。需要網路與 sudo，只跑一次
./install.sh        # 建立符號連結。可以無限次重跑

vim ~/.gitconfig.local   # 填入你的 git 身分（bootstrap 已產生範本）
exec zsh
```

先跑 `./install.sh -n` 可以乾跑，只顯示會做什麼、不動任何檔案。

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
