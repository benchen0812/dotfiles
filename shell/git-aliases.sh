# ═══════════════════════════════════════════════════════════════════════
# Git alias —— 可攜版
# ═══════════════════════════════════════════════════════════════════════
#
# 這個檔案是「自足」的：不依賴 oh-my-zsh、不依賴任何套件，bash 和 zsh 都能用。
#
# 為什麼要自足：肌肉記憶只有在「每台機器都一樣」時才有價值。
# 如果公司機器沒有這些 alias，你等於要記兩套，那不如不記。
#
# ── 在新機器上使用 ──────────────────────────────────────────────────
#
#   1. 把這個檔案複製到家目錄
#   2. 在 ~/.zshrc（或 ~/.bashrc）最後面加一行：
#
#        source ~/git-aliases.sh
#
#   3. exec zsh 重新載入
#
#   ⚠️ 一定要放在 oh-my-zsh 的 source 之後。
#      omz 的 git plugin 定義了 197 個 alias，我們要蓋過它其中幾個，
#      後定義的才會贏。
#
# ── 設計原則 ────────────────────────────────────────────────────────
#
#   1. 唯讀操作 → 用短 alias。打錯了沒後果
#   2. 有副作用 → 名稱寫清楚（gpush 而非 gp），讓手指慢下來
#   3. 破壞性   → 不做 alias，而且主動移除。要用就完整打
#
#   判斷「危險」的標準：git 幾乎能救回所有 commit 過的東西（靠 reflog），
#   救不回的只有**沒 commit 過的變更**。所有攻擊那個部分的指令都算危險。
#
# ═══════════════════════════════════════════════════════════════════════


# ───────────────────────────────────────────────────────────────────────
# 0. 先移除危險與易混淆的 alias
# ───────────────────────────────────────────────────────────────────────
#
# oh-my-zsh 預設就定義了這些。移除之後打它們會得到 "command not found" ——
# 那是刻意的：大聲失敗永遠比安靜做錯好。
#
# 2>/dev/null 是把錯誤訊息丟掉。沒有 omz 的機器上這些 alias 本來就不存在，
# unalias 會噴 "no such hash table element"，我們不想看到那個。

# 不可復原（工作目錄直接消失）
unalias gpristine 2>/dev/null   # git reset --hard && git clean -dfx
                                #   連 .gitignore 忽略的檔案都刪 —— .env、憑證全沒
unalias gwipe     2>/dev/null   # git reset --hard && git clean -df
unalias gclean    2>/dev/null   # git clean --interactive -d  刪未追蹤檔案
unalias grhh      2>/dev/null   # git reset --hard  丟掉所有未提交的修改
unalias grs       2>/dev/null   # git restore       丟棄單一檔案的修改
unalias grss      2>/dev/null   # git restore --source

# stash 消失（stash 不在 reflog 裡，刪了就真的沒了）
unalias gstc      2>/dev/null   # git stash clear  一次刪光所有 stash，最陰險的一個
unalias gstd      2>/dev/null   # git stash drop

# 改寫別人看得到的歷史
unalias 'gpf!'    2>/dev/null   # git push --force  覆蓋遠端，可能蓋掉同事的 commit
unalias gbD       2>/dev/null   # git branch -D     強制刪分支（未合併也刪）

# 會默默丟東西
unalias grbs      2>/dev/null   # git rebase --skip  跳過一個 commit，不留痕跡

# 易混淆（不危險，但容易誤觸）
unalias gp        2>/dev/null   # omz 的 push。我們用 gpush，字面清楚
unalias gl        2>/dev/null   # omz 的 pull。它緊鄰 glo/glog/glg（都是 log），
                                #   少打一個字母就從「看歷史」變成「拉取」


# ───────────────────────────────────────────────────────────────────────
# 1. 唯讀 —— 看狀態與差異
# ───────────────────────────────────────────────────────────────────────
# 這一區全部零風險，打錯了最多是看到不想看的東西。

alias g='git'

alias gst='git status'          # 完整狀態，含提示文字
alias gss='git status --short'  # 精簡：兩欄符號 + 檔名
                                #   第一欄 = 暫存區狀態，第二欄 = 工作目錄狀態
                                #   M=修改 A=新增 D=刪除 ??=未追蹤
alias gsb='git status --short --branch'   # 精簡 + 分支與領先/落後資訊

# diff 的三種比較對象，搞清楚差別很重要：
alias gd='git diff'             # 工作目錄 vs 暫存區 → 「我改了但還沒 add 的」
alias gds='git diff --staged'   # 暫存區 vs 上次 commit → 「我 add 了要提交的」
alias gdw='git diff --word-diff'  # 逐「字」比對而非逐「行」，改文件時好讀很多


# ───────────────────────────────────────────────────────────────────────
# 2. 唯讀 —— 看歷史
# ───────────────────────────────────────────────────────────────────────

alias glo='git log --oneline --decorate'
                                # --oneline  一個 commit 一行
                                # --decorate 顯示分支與標籤名稱

alias glog='git log --oneline --decorate --graph'
                                # --graph 左邊畫出分支合併的線條

alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
                                # 自訂格式：紅色雜湊 - 分支標籤 訊息 (相對時間) <作者>
                                # %ar = "3 days ago" 這種相對時間，比絕對日期好讀

alias glg='git log --stat'      # 每個 commit 附帶「哪些檔案改了幾行」

alias gbl='git blame -w'        # 每一行是哪個 commit、哪個人改的
                                # -w 忽略純空白的變更，才不會全部指向某次排版

alias grl='git reflog'          # ★ HEAD 移動的完整歷史
                                #
                                # oh-my-zsh 完全沒有這個 alias，但它是事故復原
                                # 最重要的指令。rebase 做壞了、reset --hard 砍掉了
                                # commit、誤刪分支 —— 全都靠它找回舊的 hash。
                                #
                                # 關鍵觀念：那些「消失」的 commit 其實還在，
                                # 只是沒有任何指標指向它們。reflog 記得指標去過哪裡。
                                #
                                # 用法：grl 找到目標 hash，然後 git reset --hard <hash>


# ───────────────────────────────────────────────────────────────────────
# 3. 唯讀 —— 分支與遠端
# ───────────────────────────────────────────────────────────────────────

alias gb='git branch'           # 本地分支
alias gba='git branch --all'    # 含遠端分支
alias gbv='git branch -vv'      # ★ 顯示每個分支「追蹤誰」「領先/落後幾個 commit」
                                #   想搞懂 upstream / tracking branch 是什麼，看這個

alias gf='git fetch'            # 只抓遠端更新，不動你的工作目錄。永遠安全
alias grv='git remote -v'       # 看 remote 指向哪些 URL

alias gstl='git stash list'     # 有哪些 stash
alias gsts='git stash show -p'  # 看最上面那個 stash 的內容（-p = 顯示 diff）


# ───────────────────────────────────────────────────────────────────────
# 4. 日常 —— 暫存與提交
# ───────────────────────────────────────────────────────────────────────

alias ga='git add'
alias gaa='git add --all'       # 所有變更，含新檔案與刪除

alias gapa='git add --patch'    # ★ 逐「區塊」挑選要提交的部分
                                #
                                # 同一個檔案裡改了兩件事，想分成兩個 commit 時用。
                                # 它會一塊一塊問你 y(要) / n(不要) / s(再切小塊)。
                                #
                                # 這個指令會直接改善你的 commit 品質，值得花時間學。

alias gc='git commit --verbose' # --verbose 會在編輯器裡把 diff 一起顯示出來，
                                # 讓你寫訊息時看得到自己到底改了什麼

alias gcmsg='git commit -m'     # 一行帶訊息，不開編輯器

# ⚠️ 下面兩個看起來像，但行為不同 ⚠️
alias gcam='git commit -a -m'   # -a = 自動暫存「已追蹤」檔案的修改與刪除
                                #      ★ 新檔案不會被包含，而且不會有警告

alias gac='git add --all && git commit -m'
                                # 先 add 全部（含新檔案）再提交
                                #
                                # 這是「全部塞進去」的大鎚，方便但危險：
                                # .env、暫存檔、除錯 log 都會一起進去。
                                # ★ 用之前先 gss 看一眼


# ───────────────────────────────────────────────────────────────────────
# 5. 日常 —— 分支切換
# ───────────────────────────────────────────────────────────────────────

alias gco='git checkout'        # 切分支（也能還原檔案，checkout 一詞多義是 git 的設計失誤）
                                #
                                # ⚠️ 如果你手指習慣打 gc 想切分支 —— 那是舊習慣，切分支是 gco。
                                #    gc 在所有裝了 oh-my-zsh 的機器上都是 git commit，
                                #    覆蓋它會讓你在別台機器上靜默做錯事。多打一個 o 換通用性。
alias gcb='git checkout -b'     # 建立並切換到新分支
alias gcm='git checkout $(_g_main_branch)'   # 切回主分支，自動判斷 main 還是 master

alias gbd='git branch --delete' # 安全刪除：未合併的分支會被擋下來
                                # （強制版 gbD 已被移除，要強刪就完整打 git branch -D）

# 註：git 2.23 之後有語意更清楚的 git switch（只做切分支）與 git restore（只還原檔案），
#     專門解決 checkout 一詞多義的問題。但 checkout 仍是所有教學與同事的通用語言，
#     所以先學這套。等 git 熟了再換 switch，那時你會真正理解它好在哪。


# ───────────────────────────────────────────────────────────────────────
# 6. 有副作用 —— 遠端同步
# ───────────────────────────────────────────────────────────────────────
# 這一區刻意不用兩個字母的縮寫，名稱就寫著 push / pull，不需要記憶對應關係。

alias gpush='git push'

alias gpushu='git push -u origin HEAD'
                                # 新分支第一次推，同時設定 upstream。
                                #
                                # HEAD 在這裡代表「當前分支」，不需要任何輔助函式 ——
                                # 這是最可攜的寫法。
                                #
                                # 註：如果那台機器的 gitconfig 有
                                #     push.autoSetupRemote = true，直接 gpush 就會處理，
                                #     不需要這個。但公司機器可能沒有，所以留著。

alias gpull='git pull'          # 預設是 fetch + merge

alias gpullr='git pull --rebase'
                                # fetch + rebase：把你的 commit 重播到遠端最新之後，
                                # 歷史保持線性，不產生 "Merge branch..." 這種空 commit。
                                #
                                # 為什麼用 alias 而不是設定 pull.rebase = true：
                                # 設定檔會讓 `git pull` 在這台機器上靜默做別的事，
                                # 到別台機器產生不同歷史而你不會發現。
                                # 寫成 alias，意圖就寫在指令上。

alias gamend='git commit --amend --no-edit'
                                # 把新的變更併進「上一個 commit」，訊息不變。
                                #
                                # ⚠️ 這會改寫歷史。已經 push 出去的 commit 不要用，
                                #    否則下次 push 會被拒絕（或需要 force push）。
                                #    只對「還沒推出去的」commit 使用。
                                #
                                # 取代 omz 的 gc! —— ! 在 shell 有歷史展開的特殊意義，
                                # 某些情境要跳脫，很麻煩。


# ───────────────────────────────────────────────────────────────────────
# 7. Stash（暫存未完成的工作）
# ───────────────────────────────────────────────────────────────────────

alias gsta='git stash push'     # 把目前的修改收起來，工作目錄回到乾淨狀態
                                # （omz 沒有這個短寫）

alias gstp='git stash pop'      # 取回最上面的 stash 並從清單移除
                                # 有衝突時 stash 會保留，不會消失，所以不算破壞性

# 註：gstc（stash clear）與 gstd（stash drop）已被移除。
#     stash 不在 reflog 裡，刪掉是真的找不回來。


# ───────────────────────────────────────────────────────────────────────
# 8. Rebase / Merge
# ───────────────────────────────────────────────────────────────────────
# 有 grl（reflog）和下面的 abort 系列當安全網，所以這裡可以大膽練習。

alias grb='git rebase'
alias grbi='git rebase --interactive'
                                # 互動式 rebase：可以合併、改訊息、重排、刪除 commit。
                                # 整理歷史最主要的工具。
                                # 用法：grbi HEAD~5 表示要處理最近 5 個 commit

alias grbc='git rebase --continue'   # 解完衝突後繼續
alias grba='git rebase --abort'      # ★ 完全放棄，回到 rebase 之前的狀態。救命用
alias grbom='git rebase origin/$(_g_main_branch)'
                                # 把當前分支重播到「遠端主分支的最新狀態」之上

alias gm='git merge'
alias gmc='git merge --continue'
alias gma='git merge --abort'        # ★ 同樣是救命用

# 註：grbs（rebase --skip）已被移除 —— 它會默默丟掉一個 commit 且不留痕跡。


# ───────────────────────────────────────────────────────────────────────
# 9. 輔助函式
# ───────────────────────────────────────────────────────────────────────

# 偵測這個 repo 的主分支叫 main 還是 master。
#
# 公司 repo 有些用 main 有些用 master，硬寫死一個就會在另一種上失敗。
#
# 函式名稱前面加底線，表示這是內部用的，不要直接呼叫。
# 也刻意跟 oh-my-zsh 的 git_main_branch 用不同名字，避免覆蓋它 ——
# omz 其他 alias 依賴那個函式，蓋掉會出事。
_g_main_branch() {
  local branch
  for branch in main trunk master; do
    # show-ref --verify 檢查某個 ref 是否存在
    # -q 安靜模式：不輸出，只用回傳值表示結果
    if git show-ref -q --verify "refs/heads/$branch" 2>/dev/null; then
      echo "$branch"
      return
    fi
  done
  # 都找不到就猜 main（例如全新的空 repo）
  echo "main"
}
