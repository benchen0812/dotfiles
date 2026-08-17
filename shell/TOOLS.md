# 終端機工具手冊

`bootstrap.sh` 安裝的工具怎麼用。設定在 [`tools.sh`](tools.sh)（每行都有註解）。

那個檔案是**可攜**的：公司機器用最小安裝（`work-install.sh`）也吃得到同一份 ——
包含 fzf 的鍵位。工具本身要自己 `brew install`，`work-install.sh` 刻意不裝套件。

git 相關的另外看 [`README.md`](README.md)。

---

## 速查：新增的鍵位

裝完之後多出這些，**不需要記指令**：

| 按鍵 | 作用 | 來自 |
|---|---|---|
| `Ctrl-R` | 模糊搜尋**歷史指令** | fzf |
| `Ctrl-T` | 模糊搜尋**檔案**，選中插入到指令列 | fzf |
| `Alt-C` | 模糊搜尋**目錄**並 `cd` 過去 | fzf |
| `→` | 接受灰字歷史建議（整行） | zsh-autosuggestions |
| `Ctrl-→` | 只接受建議的**下一個字** | zsh-autosuggestions |
| `Esc Esc` | — | （`sudo` plugin 刻意沒裝） |

## 速查：新增的指令

| 指令 | 取代 | 一句話 |
|---|---|---|
| `z <關鍵字>` | `cd 長路徑` | 跳到常去的目錄 |
| `zi` | — | 互動式選目錄 |
| `rg <字串>` | `grep -r` | 搜檔案內容，快很多 |
| `fd <檔名>` | `find` | 搜檔名，語法人性化 |
| `bat <檔案>` | `cat` | 語法高亮 + 行號 |
| `shellcheck <script>` | — | 檢查 shell 腳本的錯誤 |

---

# fzf —— 模糊搜尋

**「terminal 快速導航」的核心答案。**

## 三個鍵位

### `Ctrl-R` —— 搜歷史（最常用）

想重複之前打過的指令時，**不要按上鍵一直翻**。按 `Ctrl-R`，打幾個字：

```
$ [按 Ctrl-R]
> dock com
  docker compose up -d --build
  docker compose logs -f api
  docker compose down
```

### `Ctrl-T` —— 搜檔案

在指令打到一半時按，選中的路徑會**插入到游標位置**：

```
$ vim [按 Ctrl-T]
    → 選一個檔案 →
$ vim src/connectors/web/web-plugin.ts
```

右側有預覽視窗（bat 語法高亮，前 200 行）。

### `Alt-C` —— 搜目錄並 cd

跟 `z` 的差別：`Alt-C` 搜的是**當前目錄底下**的所有子目錄；`z` 搜的是**你去過的**目錄（可能在任何地方）。

> ⚠️ **macOS 上這個鍵預設是死的。** Option 鍵要先對應到 Meta：
> iTerm2 把 Left Option 設成 `Esc+`；Terminal.app 勾「Use Option as Meta key」。
> 這是終端機的設定問題，不是 fzf 或我們的設定有問題 ——
> `Ctrl-R` 和 `Ctrl-T` 不受影響。

---

## 模糊搜尋的語法（很多人不知道）

預設是模糊比對——**字元順序對就好，不用連續**。搜 `dcub` 能找到 `docker compose up --build`。

但也支援精確語法：

| 打法 | 意思 | 例 |
|---|---|---|
| `abc` | 模糊（預設） | 找 `a...b...c` |
| `'abc` | **精確**包含 | 只找真的有 `abc` 的 |
| `^abc` | 開頭是 | |
| `abc$` | 結尾是 | `.ts$` 找 TypeScript 檔 |
| `!abc` | **排除** | `!test` 排掉測試檔 |
| `abc \| def` | 或 | `.ts$ \| .js$` |
| 空格分隔 | 且 | `src test` 兩個都要有 |

實用組合：

```
'component !test .tsx$        含 component、不含 test、且是 .tsx 結尾
```

## 當成選單用（進階）

fzf 可以接在任何管線後面，把輸出變成互動選單：

```bash
git branch | fzf                                  # 用選的切分支
kill -9 $(ps aux | fzf | awk '{print $2}')        # 用選的砍行程
cd $(fd --type d | fzf)                           # 用選的進目錄
```

## 我們的設定，以及為什麼

寫在 [`tools.sh`](tools.sh)。

**所有 `FZF_*` 都只在「該機器沒設過」時才設** —— 因為這個檔案會被載進
公司機器，覆蓋人家既有的 fzf 設定等於安靜地改變既有行為。
沒有既有設定的機器（絕大多數）行為跟直接 `export` 完全一樣。

### `FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'`

**fzf 預設用 `find` 掃描，會把 `node_modules`、`.git`、build 產物全部掃進來** ——
又慢又都是雜訊。

改用 `fd` 之後，它**預設就尊重 `.gitignore`**。差異很大：
在一個有 `node_modules` 的專案裡，`Ctrl-T` 的候選從幾萬筆降到幾百筆。

| 參數 | 作用 |
|---|---|
| `--type f` | 只要檔案 |
| `--hidden` | 包含點開頭的隱藏檔 |
| `--exclude .git` | 但 `.git` 內部還是不要 |

### `FZF_CTRL_T_OPTS` —— bat 預覽

選檔案時右側顯示語法高亮的內容預覽，前 200 行。
沒裝 bat 的機器會自動退回 `head -200`。

### `FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'`

不要佔滿整個畫面，搜尋框放上面（比較符合直覺）。

---

# zoxide —— 智慧 cd

## 用法

```bash
z systems          # 跳到記憶中最匹配的目錄
z mit tracks       # 多關鍵字，全部都要匹配
zi                 # 互動選單（用 fzf 挑）
z -                # 回上一個目錄
```

## ⚠️ 前兩天你會覺得它沒用

**它必須先「看到」你去過那個目錄，才記得住。**

```bash
cd ~/ubuntu-project/MITOpenCourse/tracks/1-systems    # 正常走一次
cd ~
z systems                                              # 之後才能跳
```

排名依據是「**去過幾次 × 多久以前去的**」，所以用越久越準。
第三天開始才會有感 —— 前兩天你會習慣性地打完整路徑，那是正常的。

## 為什麼它必須是 shell 函式

`cd` 改變的是「行程自己的當前目錄」，而子行程死掉時那個狀態就消失了。
所以跳目錄這件事**必須在你當前的 shell 內執行**，不能是一支獨立的 script。

`zoxide init zsh` 產生的就是那段函式定義，`eval` 把它注入當前 shell。
沒有那行 `eval`，你只會有 `zoxide` 這個執行檔，但**沒有 `z` 指令**。

（這跟 `mkcd` 必須是函式而不能是 script 是完全相同的道理。）

---

# ripgrep（`rg`）—— 搜內容

取代 `grep -r`。快非常多，而且**預設就跳過 `.gitignore` 裡的東西和 `.git/`**。

```bash
rg "TODO"                    # 遞迴搜整個目錄
rg "func.*Handler" -t go     # 只搜 .go 檔
rg "error" -A 3 -B 1         # 顯示命中行的後 3 行、前 1 行
rg -i "warning"              # 忽略大小寫
rg -l "import react"         # 只列出檔名，不列內容
rg -c "console.log"          # 每個檔案的命中次數
rg "x" --hidden              # 包含隱藏檔
rg "x" --no-ignore           # 不理會 .gitignore
```

| 參數 | 意思 |
|---|---|
| `-t <類型>` | 限定檔案類型（`rg --type-list` 看有哪些） |
| `-A N` / `-B N` / `-C N` | after / before / 前後各 N 行 |
| `-i` | 忽略大小寫 |
| `-l` | 只列檔名 |
| `-c` | 只算次數 |
| `-w` | 全字匹配 |
| `-v` | 反向（列出**不含**的行） |

---

# fd —— 搜檔名

取代 `find`。同樣預設尊重 `.gitignore`。

```bash
# find 的寫法                        # fd 的寫法
find . -name "*.md" -type f     →    fd -e md
find . -iname "*config*"        →    fd config
find . -type d -name "src"      →    fd -t d src
```

```bash
fd config                    # 檔名含 config
fd -e ts -e tsx              # 副檔名是 ts 或 tsx
fd -t d                      # 只要目錄
fd -H secret                 # 含隱藏檔
fd -I node_modules           # 不理會 .gitignore
fd -e log -x rm              # 找到的每個檔案執行 rm（危險，先不加 -x 確認）
```

| 參數 | 意思 |
|---|---|
| `-e <副檔名>` | 副檔名（可重複） |
| `-t f` / `-t d` | 只要檔案 / 只要目錄 |
| `-H` | 含隱藏檔 |
| `-I` | 不理會 `.gitignore` |
| `-x <指令>` | 對每個結果執行指令 |

> **Ubuntu 把它裝成 `fdfind`**（避免與既有套件衝突），`bootstrap.sh` 在
> `~/.local/bin/` 建了 `fd` 的連結。`bat` 同理（原名 `batcat`）。

---

# bat —— 看檔案

取代 `cat`，加上語法高亮、行號、分頁。

```bash
bat script.sh                # 語法高亮 + 行號
bat -p file.txt              # 純輸出，不加裝飾（適合接管線）
bat -n file.txt              # 只加行號
bat -r 10:20 file.txt        # 只看第 10-20 行
rg -l "TODO" | xargs bat     # 搭配使用
```

> 接管線時記得加 `-p`，否則行號和邊框會一起被傳下去。

---

# shellcheck —— shell 腳本檢查

```bash
shellcheck install.sh
```

它會抓出這類經典問題：

- 變數沒加引號（`$var` vs `"$var"`）→ 空白會導致 word splitting
- `[ ]` 與 `[[ ]]` 用錯
- 未定義的變數
- 不必要的 `cat`（`cat file | grep` → `grep file`）

**建議裝進編輯器外掛，寫的時候就即時畫紅線。** 這比讀任何 bash 教材都有效 ——
它會在你犯錯的當下告訴你，而不是等你三個月後 debug。

---

# zsh plugin

## zsh-autosuggestions

打字時根據歷史顯示**灰色建議**：

```
$ git com                                    ← 你打的（白色）
$ git commit -m "fix the login bug"          ← 灰色部分是建議
```

| 按鍵 | 作用 |
|---|---|
| `→`（右方向鍵） | 接受**整行** |
| `Ctrl-→` | 只接受**下一個字** |
| 繼續打字 | 建議會即時更新 |
| `Esc` 或直接按 Enter | 忽略建議 |

`Ctrl-→` 那個很實用：建議前半段對、後半段不對時，只吃前半段。

## zsh-syntax-highlighting

指令**送出前**就上色：

| 顏色 | 意思 |
|---|---|
| 綠色 | 指令存在，可以執行 |
| 紅色 | 指令不存在（打錯了） |
| 底線 | 路徑存在 |

**在按 Enter 之前就知道打錯了**，不用等錯誤訊息。

> 它必須是 `plugins=()` 陣列的**最後一個**，否則抓不到後面才註冊的指令。
> `.zshrc` 裡的載入順序已經處理好了，加新 plugin 時別插到它後面。

---

# 前三天練什麼

**工具裝了不等於會用。** 一次練七個會全部忘掉，刻意練這三個就好：

| # | 練什麼 | 觸發時機 |
|---|---|---|
| 1 | **`Ctrl-R`** | 想重複之前的指令時，**別按上鍵翻**，改按 `Ctrl-R` 打幾個字 |
| 2 | **`→`** | 看到灰字建議是對的，就按右方向鍵接受 |
| 3 | **`z`** | 每次要換目錄前，先想一秒「這個我去過嗎」 |

第三個前兩天會沒感覺（zoxide 還沒記住你的習慣），**那是正常的，不要放棄**。

## 驗收

Missing Semester **S9** 會檢查這件事，而標準不是「裝好了」，是**「進了肌肉記憶沒有」**：

> 回想這兩週：`Ctrl-R` 用了幾次？如果是零，代表沒進習慣，要再刻意練。

裝好只花兩分鐘，養成習慣要兩週。後者才是真正的成本。
