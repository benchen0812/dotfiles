# 歷史紀錄設定
#
# 為什麼要調大：Ctrl-R 和 fzf 搜歷史的價值，完全取決於歷史夠不夠長。
# 預設值太小，搜三個月前打過的指令會找不到。50000 筆的檔案也才幾 MB。

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000          # 記憶體中保留的筆數
SAVEHIST=50000          # 寫入檔案的筆數

setopt EXTENDED_HISTORY       # 記錄時間戳與執行時間
setopt SHARE_HISTORY          # 多個終端機即時共享歷史
setopt HIST_IGNORE_ALL_DUPS   # 重複指令只保留最後一次（讓 Ctrl-R 結果乾淨）
setopt HIST_IGNORE_SPACE      # 以空白開頭的指令不記錄 —— 打密碼時很有用
setopt HIST_REDUCE_BLANKS     # 存檔前去掉多餘空白
setopt HIST_VERIFY            # 用 !! 或 !$ 展開後先顯示，按 Enter 才執行
setopt HIST_FIND_NO_DUPS      # 搜尋時跳過重複結果
