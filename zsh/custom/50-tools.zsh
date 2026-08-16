# 外部工具的 shell 整合
#
# 這些工具由 bootstrap.sh 安裝，但「裝了執行檔」不等於「能用」——
# 有些需要在 shell 啟動時注入函式或鍵位綁定。
#
# 全部用 command -v 守住：沒裝那個工具的機器就靜默跳過，不會噴錯。
# 設定檔不該假設環境已經備妥。

# ── zoxide：智慧 cd ──────────────────────────────────────────────────
#
# 光裝執行檔沒有用 —— 跳目錄這件事必須在「當前 shell 內」執行，
# 因為子行程改不了父行程的當前目錄。
# （這跟 mkcd 必須是函式而不能是 script 是同一個道理。）
#
# zoxide init 產生的程式碼會定義一個 __zoxide_z 函式，再把 z 設成它的 alias。
# 所以 `whence -w z` 顯示的是 alias，但實際做事的是函式。
# eval 是把那段程式碼注入當前 shell —— 沒有 eval 就只是印出文字，什麼都不會發生。
#
# 用法：
#   z proj      跳到記憶中最匹配「proj」的目錄
#   z fo bar    多關鍵字，全部要匹配
#   zi          互動選單（用 fzf 挑）
#   z -         回上一個目錄
#
# 它靠「頻率 × 最近使用」排名，所以前幾天效果不明顯 ——
# 要先 cd 過那些目錄它才記得。第三天開始會有感。
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ── fzf：讓它用 fd 而不是 find ───────────────────────────────────────
#
# fzf 預設用 find 掃描檔案，會把 node_modules、.git、build 產物全部掃進來，
# 又慢又都是雜訊。改用 fd 之後預設就尊重 .gitignore。
#
# 這個差異很大 —— 在一個有 node_modules 的專案裡，
# Ctrl-T 的候選從幾萬筆降到幾百筆。
if command -v fzf >/dev/null 2>&1 && command -v fd >/dev/null 2>&1; then
  # --type f    只要檔案
  # --hidden    包含隱藏檔（點開頭的）
  # --exclude   .git 還是不要
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

  # Alt-C 是「搜尋目錄並 cd 過去」，所以只列目錄
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

# ── fzf：預覽視窗 ────────────────────────────────────────────────────
#
# Ctrl-T 選檔案時，右側顯示內容預覽。有 bat 就用 bat（語法高亮），
# 沒有就退回 head。
#
# {} 是 fzf 的佔位符，會被換成目前反白的那一行。
if command -v fzf >/dev/null 2>&1; then
  if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
  else
    export FZF_CTRL_T_OPTS="--preview 'head -200 {}'"
  fi

  # Ctrl-R（搜歷史）的視窗設定：
  #   --height 40%     不要佔滿整個畫面
  #   --layout=reverse 搜尋框在上面，比較符合直覺
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi
