# Git Alias 使用手冊

`git-aliases.sh` 的詳細說明。檔案本身每行都有註解講「這行做什麼」，
這份文件講**「什麼時候用、怎麼用」**，附實際操作範例。

---

## 快速開始

### 在新機器上部署（含公司機器）

```bash
# 1. 把檔案弄過去
scp ~/dotfiles/shell/git-aliases.sh 目標機器:~/

# 2. 在該機器的 ~/.zshrc（或 ~/.bashrc）最後面加一行
echo 'source ~/git-aliases.sh' >> ~/.zshrc

# 3. 重載
exec zsh
```

**必須加在最後面。** 如果那台機器有 oh-my-zsh，它的 git plugin 定義了 197 個 alias，
我們要蓋掉其中幾個並移除危險的 —— 後定義的才會贏。

這個檔案零相依：不需要 oh-my-zsh、不需要安裝任何東西、bash 和 zsh 都能用。

### 確認生效

```bash
$ alias gpush
gpush='git push'

$ alias gwipe
zsh: no such hash table element: gwipe    # ← 危險的已被移除，正確
```

---

## 先學這 12 個

一次記 40 個會失敗。這 12 個涵蓋日常八成情境，用熟了其他自然會滲透進來。

| alias | 指令 | 什麼時候用 |
|---|---|---|
| `gss` | `git status --short` | **最常用。** 動手前先看一眼 |
| `gd` | `git diff` | 看我改了什麼（還沒 add 的） |
| `gds` | `git diff --staged` | 看我要提交什麼（已 add 的） |
| `ga` | `git add` | 暫存指定檔案 |
| `gcmsg` | `git commit -m` | 提交 |
| `gac` | `git add --all && git commit -m` | 全部一起提交（先 `gss` 確認！） |
| `glo` | `git log --oneline --decorate` | 看歷史 |
| `gco` | `git checkout` | 切分支 |
| `gcb` | `git checkout -b` | 開新分支 |
| `gpush` | `git push` | 推上去 |
| `gpull` | `git pull` | 拉下來 |
| `grl` | `git reflog` | **出事時的第一個指令** |

---

# 按情境查

## 情境 1：改完東西要提交

```bash
$ gss                          # 先看狀態，這一步不要省
 M src/api.js                  # M  = 已修改，未暫存
?? src/new-feature.js          # ?? = 全新檔案，git 還不認識它

$ gd                           # 看看到底改了什麼

$ ga src/api.js src/new-feature.js
$ gds                          # 確認要提交的內容
$ gcmsg "加入搜尋 API"
```

**趕時間的版本：**

```bash
$ gss                          # 還是要看！
$ gac "加入搜尋 API"            # add --all + commit 一次做完
```

> ⚠️ `gac` 會把**所有東西**收進去，包括 `.env`、除錯用的 log、暫存檔。
> 這就是為什麼前面那行 `gss` 不能省 —— 一秒鐘，換掉把密碼 commit 進歷史的意外。

---

## 讀懂 `gss` 的輸出

`gss` = `git status --short`。每個檔案一行，**兩欄符號 + 檔名**，
沒有 `gst` 那些「use git add to...」的提示文字。

```
MM both.txt
D  deleted.txt
M  edited.txt
R  oldname.txt -> newname.txt
A  staged-new.txt
?? untracked.txt
```

### 關鍵是那兩欄

```
第 1 欄 = 暫存區（已 add 的）
第 2 欄 = 工作目錄（還沒 add 的）
```

| 顯示 | 意思 |
|---|---|
| `M ` | 修改**已 add**，下次 commit 會進去 |
| ` M` | 修改了但**還沒 add**（注意第一欄是空白） |
| `MM` | **add 之後又改了** —— 只有 add 當下那一版會進 commit |
| `A ` | 新檔案已 add |
| `D ` | 刪除已 add |
| `R ` | 改名已 add（顯示 `舊名 -> 新名`） |
| `??` | git 完全不認識這個檔案（未追蹤） |
| `!!` | 被 `.gitignore` 忽略（要加 `--ignored` 才會顯示） |
| `UU` | 合併衝突，雙方都改了同一處 |

**`MM` 是最容易踩的坑。** 你以為改的東西都會進去，
實際上只有 `git add` 當下那一版會 —— 之後又改的部分留在工作目錄。

### 相關的三個變體

| alias | 指令 | 差別 |
|---|---|---|
| `gst` | `git status` | 完整版，含提示文字 |
| `gss` | `git status --short` | 精簡，一行一個檔案 |
| `gsb` | `git status --short --branch` | 精簡 + 最上面多一行分支與領先/落後 |

### 為什麼這是最該養成的習慣

**它是唯一能在你按下 commit 之前，一眼看出「哪些東西會被收進去」的指令。**

`gac`（= `add --all` + commit）把兩個動作綁在一起，中間沒有讓你確認的瞬間。
先打一次 `gss`，那一秒鐘就是你發現「欸這是別人的 repo」或
「`.env` 怎麼在裡面」的機會。

---

### `gac` 和 `gcam` 差在哪（重要）

```bash
$ echo "改動" >> 舊檔.txt
$ echo "新的" > 新檔.txt

$ gcam "提交"                  # git commit -a -m
 1 file changed                # ← 只收了舊檔.txt

$ gss
?? 新檔.txt                    # ← 新檔案沒進去，而且完全沒有警告
```

| | 已追蹤檔案的修改 | 新檔案 |
|---|---|---|
| `gcam` = `git commit -a -m` | ✅ | ❌ **不含** |
| `gac` = `git add --all && git commit -m` | ✅ | ✅ |

`-a` 的定義是「自動暫存**已被追蹤**的檔案」。git 不認識的新檔案不在範圍內。

---

## 情境 2：一個檔案改了兩件事，想拆成兩個 commit

用 `gapa`（`git add --patch`）逐區塊挑選：

```bash
$ gapa
diff --git a/src/api.js b/src/api.js
@@ -10,6 +10,8 @@ function search(q) {
+  // 修正 bug：空字串會炸
+  if (!q) return []
   return db.query(q)
(1/2) Stage this hunk [y,n,q,a,d,s,e,?]? y      ← 這塊要

@@ -25,3 +27,7 @@ function search(q) {
+// TODO: 之後要加分頁
(2/2) Stage this hunk [y,n,q,a,d,s,e,?]? n      ← 這塊不要

$ gcmsg "修正空查詢字串會炸的問題"
$ gss                          # TODO 那段還留在工作目錄
```

**互動選項：**

| 鍵 | 作用 |
|---|---|
| `y` | 要這塊 |
| `n` | 不要這塊 |
| `s` | 這塊太大，再切小一點 |
| `e` | 手動編輯要收哪幾行 |
| `q` | 離開 |
| `?` | 顯示說明 |

> 這個指令會直接改善你的 commit 品質。一個 commit 只做一件事，日後 `git bisect`
> 找 bug、review、revert 都會輕鬆很多。

---

## 情境 3：開新分支做功能，然後推上去

```bash
$ gcm                          # 先切回主分支（自動判斷 main 還是 master）
$ gpull                        # 更新到最新
$ gcb feature/search           # 開新分支並切過去

# ... 做事、提交 ...

$ gpushu                       # 第一次推：-u 同時建立追蹤關係
$ gpush                        # 之後永遠只要這樣
```

### 為什麼第一次要用 `gpushu`

`u` = `-u` = `--set-upstream`，它建立「這個本地分支對應哪個遠端分支」的記錄。

沒有這個記錄，git 不知道 `gpush` / `gpull` 該去哪裡：

```bash
$ gpush
fatal: The current branch feature/search has no upstream branch.
```

用 `gpushu` 設定一次之後，這個分支就永遠不用再管了。

> ⚠️ **`git push origin HEAD` 不會建立追蹤關係。**
> 它推得上去，但下次 `gpush` 還是會失敗，你得每次都打完整版。`-u` 只需要一次。

### 看追蹤關係

```bash
$ gbv
* feature/search  a3f2b1 [origin/feature/search: ahead 2] 加了搜尋
  main            9c8d7e [origin/main] 修正登入
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 這段就是 upstream 資訊
```

`ahead 2` = 你有 2 個 commit 還沒推上去。**想搞懂 upstream 是什麼，看這個指令最快。**

---

## 情境 4：出事了，要救回來

**第一個指令永遠是 `grl`（reflog）。**

```bash
$ grl
932c208 HEAD@{0}: rebase (finish): returning to refs/heads/feature
a3f2b1c HEAD@{1}: rebase (pick): 加了搜尋
7d4e9f2 HEAD@{2}: rebase (start): checkout main
c1b8a03 HEAD@{3}: commit: 加了搜尋功能        ← rebase 之前的狀態
```

reflog 記錄的是 **HEAD 去過哪裡**。

### 核心觀念

那些「消失」的 commit **其實還在**。git 不會立刻刪除任何東西 ——
它們只是失去了指標，沒有分支指向它們而已。reflog 記得那些指標的移動歷史。

所以幾乎所有 git 事故的解法都是同一招：

```
grl 找到出事前的 hash  →  git reset --hard <hash>
```

### 常見事故對照表

| 症狀 | 解法 |
|---|---|
| rebase 到一半衝突，想放棄 | `grba` |
| rebase 做完了但結果是錯的 | `grl` 找 rebase 前的 hash → `git reset --hard <hash>` |
| merge 到一半想放棄 | `gma` |
| `reset --hard` 砍掉了還沒 push 的 commit | `grl` → `git reset --hard <hash>` |
| 誤刪分支 | `grl` 找到該分支最後的 commit → `git checkout -b <分支名> <hash>` |
| commit 訊息打錯（還沒 push） | `gamend` 或 `git commit --amend` |
| commit 進了不該進的檔案（還沒 push） | `git reset --soft HEAD~1` 拆開重來 |
| 在錯的分支上寫了東西（還沒 commit） | `gsta` → `gco 正確分支` → `gstp` |
| 用錯身分 commit 了（最後一個） | `git commit --amend --reset-author --no-edit` |

### git 唯一救不回來的東西

**沒有 commit 過的變更。**

commit 過的幾乎都能靠 reflog 找回；沒 commit 的一旦被覆蓋，就真的沒了。
這就是為什麼下面這些指令被移除 —— 它們攻擊的正好是那個部分。

---

## 情境 5：整理歷史（rebase）

```bash
$ grbi HEAD~5                  # 處理最近 5 個 commit
```

編輯器會開啟一份清單：

```
pick a1b2c3 加了搜尋
pick d4e5f6 修正 typo          ← 想併進上面那個
pick 7g8h9i 修正 typo 的 typo   ← 也想併進去
pick j1k2l3 加了分頁
pick m4n5o6 WIP                ← 想改訊息
```

把 `pick` 改成：

| 指令 | 作用 |
|---|---|
| `pick` | 保留（預設） |
| `squash` / `s` | 併入上一個，**兩個訊息都保留讓你編輯** |
| `fixup` / `f` | 併入上一個，**丟掉自己的訊息** ← 修 typo 用這個 |
| `reword` / `r` | 保留變更，只改訊息 |
| `drop` / `d` | 整個刪掉 |
| 調換行的順序 | 就會改變 commit 順序 |

**做壞了怎麼辦：**

```bash
$ grba                         # 還在 rebase 過程中 → 直接放棄
$ grl                          # 已經做完了 → 找 rebase (start) 前一個 hash 回去
```

> ⚠️ **只對還沒 push 的 commit 做 rebase。** 已經推出去的東西被改寫，
> 別人拉下來會爆炸。

### 把分支更新到主分支最新狀態

```bash
$ gf                           # 先抓遠端更新（安全，不動工作目錄）
$ grbom                        # rebase 到 origin/main 之上
```

有衝突就解，然後 `grbc` 繼續。想放棄就 `grba`。

> `rerere` 已經在 `.gitconfig` 開啟 —— 同一個衝突解過一次，之後自動套用。
> rebase 一長串 commit 時，同個衝突可能重複出現五次，這個設定省掉四次。

---

## 情境 6：手上的事做到一半，要臨時切去修 bug

```bash
$ gsta                         # 收起來，工作目錄變乾淨
$ gco hotfix                   # 切去修 bug
# ... 修完 ...
$ gco -                        # 切回原本的分支（- 代表上一個分支）
$ gstp                         # 拿回來
```

**查看有哪些 stash：**

```bash
$ gstl                         # 清單
stash@{0}: WIP on feature: a3f2b1 加了搜尋
$ gsts                         # 看最上面那個的內容
```

> `gstp`（pop）取回並移除該筆。有衝突時 stash 會保留不會消失，所以不算破壞性。
>
> ⚠️ 但 `git stash drop` 和 `git stash clear` **是**破壞性的 ——
> **stash 不在 reflog 裡，刪掉就真的找不回來。** 所以那兩個沒有 alias。

---

## 情境 7：查這行是誰寫的、為什麼

```bash
$ gbl src/api.js               # git blame -w
a3f2b1c (Ben  2026-08-15) function search(q) {
c1b8a03 (Alice 2026-07-02)   if (!q) return []
```

`-w` 忽略純空白的變更 —— 沒有它的話，整個檔案會全部指向某次「重新排版」的 commit。

找到可疑的 commit 之後：

```bash
$ git show a3f2b1c             # 看那次改了什麼、commit 訊息寫什麼
```

**找出是哪次改壞的：**

```bash
$ gbs start
$ gbs bad                      # 現在是壞的
$ gbs good v1.0                # v1.0 是好的
# git 自動二分，每次跳到中間讓你測試
$ gbs good    /  $ gbs bad     # 回報結果
# ... 重複幾次，git 直接告訴你是哪個 commit
$ gbs reset                    # 結束，回到原本位置
```

---

# 完整清單

## 唯讀（零風險）

| alias | 指令 |
|---|---|
| `g` | `git` |
| `gst` | `git status` |
| `gss` | `git status --short` |
| `gsb` | `git status --short --branch` |
| `gd` | `git diff`（工作目錄 vs 暫存區） |
| `gds` | `git diff --staged`（暫存區 vs 上次 commit） |
| `gdw` | `git diff --word-diff`（逐字比對） |
| `glo` | `git log --oneline --decorate` |
| `glog` | `git log --oneline --decorate --graph` |
| `glol` | 彩色圖形 log，含作者與相對時間 |
| `glg` | `git log --stat` |
| `gbl` | `git blame -w` |
| `grl` | **`git reflog`** |
| `gb` | `git branch` |
| `gba` | `git branch --all` |
| `gbv` | `git branch -vv`（看追蹤關係） |
| `gf` | `git fetch` |
| `grv` | `git remote -v` |
| `gstl` | `git stash list` |
| `gsts` | `git stash show -p` |

## 日常

| alias | 指令 |
|---|---|
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gapa` | `git add --patch` |
| `gc` | `git commit --verbose` |
| `gcmsg` | `git commit -m` |
| `gcam` | `git commit -a -m`（不含新檔案） |
| `gac` | `git add --all && git commit -m`（含新檔案） |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gcm` | `git checkout <主分支>` |
| `gbd` | `git branch --delete`（安全刪除） |
| `gsta` | `git stash push` |
| `gstp` | `git stash pop` |

## 有副作用（名稱寫清楚）

| alias | 指令 |
|---|---|
| `gpush` | `git push` |
| `gpushu` | `git push -u origin HEAD`（第一次推新分支） |
| `gpull` | `git pull` |
| `gpullr` | `git pull --rebase` |
| `gamend` | `git commit --amend --no-edit` |

## Rebase / Merge

| alias | 指令 |
|---|---|
| `grb` | `git rebase` |
| `grbi` | `git rebase --interactive` |
| `grbc` | `git rebase --continue` |
| `grba` | `git rebase --abort` |
| `grbom` | `git rebase origin/<主分支>` |
| `gm` | `git merge` |
| `gmc` | `git merge --continue` |
| `gma` | `git merge --abort` |

---

# 被移除的（要用請完整打）

這些 oh-my-zsh 有定義，我們主動移除。打它們會得到 `command not found` ——
**那是刻意的：大聲失敗永遠比安靜做錯好。**

| 被移除 | 原指令 | 為什麼 |
|---|---|---|
| `gpristine` | `git reset --hard && git clean -dfx` | **連 `.gitignore` 忽略的檔案都刪** —— `.env`、憑證、node_modules 全沒 |
| `gwipe` | `git reset --hard && git clean -df` | 未追蹤檔案全刪 |
| `gclean` | `git clean --interactive -d` | 刪未追蹤檔案 |
| `grhh` | `git reset --hard` | 丟掉所有未提交的修改 |
| `grs` | `git restore` | 丟棄單一檔案的修改 |
| `grss` | `git restore --source` | 同上 |
| `gstc` | `git stash clear` | **一次刪光所有 stash。** stash 不在 reflog 裡，救不回 |
| `gstd` | `git stash drop` | 同上 |
| `gpf!` | `git push --force` | 覆蓋遠端，可能蓋掉同事的 commit |
| `gbD` | `git branch -D` | 強制刪分支（未合併也刪） |
| `grbs` | `git rebase --skip` | 默默丟掉一個 commit，不留痕跡 |
| `gp` | `git push` | 不危險，但用 `gpush` 更清楚 |
| `gl` | `git pull` | **緊鄰 `glo`/`glog`/`glg`（都是 log）**，少打一個字母就從看歷史變成拉取 |

多打 15 個字元，換掉一次無法復原的意外。

---

# 命名規則

不是背 40 個，是懂一套規則。

```
g  +  指令首字母  +  旗標首字母
```

| | |
|---|---|
| `g` | git |
| `ga` | **a**dd |
| `gb` | **b**ranch |
| `gc` | **c**ommit |
| `gco` | **c**heck**o**ut |
| `gd` | **d**iff |
| `gf` | **f**etch |
| `gm` | **m**erge |
| `grb` | **r**e**b**ase |
| `gst` | **st**atus |
| `gsta` | **sta**sh |

**多一個字母 = 多一個旗標：**

| 基礎 | 加旗標 |
|---|---|
| `gd` → `gds` | `--staged` |
| `gb` → `gba` | `--all` |
| `grb` → `grbi` | `--interactive` |
| `gpush` → `gpushu` | `-u` |

## 兩個例外，以及為什麼

| | 規則會給的名字 | 我們用的 | 原因 |
|---|---|---|---|
| push | `gp` | **`gpush`** | 有副作用的東西應該讓手指慢下來 |
| pull | `gl` | **`gpull`** | `gl` 太靠近 `glo`/`glog`/`glg` |

**設計原則：唯讀操作用短 alias（打錯沒後果），有副作用的名稱寫清楚（讓腦袋跟上），破壞性的不做 alias。**

---

# 常見疑問

**Q：為什麼 `gc` 不是 checkout？**

`gc` 在所有裝了 oh-my-zsh 的機器上都是 `git commit`。覆蓋它的話，
你在沒載入這個檔案的機器上打 `gc feature-x` 會執行 `git commit feature-x` ——
**靜默做別的事**。切分支是 `gco`，多打一個字母換通用性。

**Q：我在別台機器上打 `gpush`，說 command not found？**

那台沒有載入這個檔案。這是**安全的失敗** —— 它大聲告訴你出問題了，
而不是安靜地做別的事。這就是為什麼我們只「新增」名稱、不「覆蓋」既有名稱。

| 你做的事 | 別台機器上會怎樣 | 安全嗎 |
|---|---|---|
| 覆蓋既有名稱（`gc` 改成 checkout） | 靜默執行別的動作 | ❌ |
| 新增新名稱（`gpush`） | `command not found` | ✅ |
| 移除既有名稱（`unalias gl`） | 那台照常有 | ✅ |

**Q：`git st`（git alias）和 `gst`（shell alias）差在哪？**

| | 定義在哪 | 需要 | 特點 |
|---|---|---|---|
| `git st` | `~/.gitconfig` 的 `[alias]` | 有 git 就有 | 跟著 gitconfig 走，任何 shell 都有效 |
| `gst` | 這個檔案 | 要 source | 更短 |

兩套並存不衝突。這個檔案裡的是 shell 層的。
