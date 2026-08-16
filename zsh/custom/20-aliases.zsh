# Alias
#
# 加新 alias 就往這裡加。加完記得順手更新 ~/dotfiles/MANIFEST.md，
# 否則半年後你會看到一行不知道自己為什麼寫的東西。
#
# 判斷該不該放進來：這個 alias 換到別台機器還有意義嗎？
# 沒有的話就不該進這個 repo —— 這裡是跨機器的工具庫，不是這台機器的設定備份。

# ── dotfiles 自身 ────────────────────────────────────────────────────
alias dot='cd ~/dotfiles'
alias zshrc='$EDITOR ~/dotfiles/zsh/.zshrc'

# exec zsh 是用新的 zsh 取代目前這個行程，等於完整重跑一次啟動流程。
# 比 `source ~/.zshrc` 乾淨 —— source 會在既有環境上疊加，
# 舊的 alias、函式、變數不會消失，改壞的東西可能被舊值蓋住看不出來。
alias reload='exec zsh'
