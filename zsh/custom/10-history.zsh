# 歷史紀錄設定
#
# 實際內容在 ~/dotfiles/shell/history.sh —— 那是「可攜版」，
# 自足、零相依，公司機器用「一行 source」的方式也吃得到同一份設定。
#
# 為什麼分開放：如果直接寫在這裡，就跟 zsh/custom/ 的載入機制綁在一起，
# 沒有整套 dotfiles 的機器就用不到。
# 而且改一個地方要兩台機器同時生效 —— 兩份會發散，發散就等於沒有設定。
#
# 這跟 40-git.zsh 是同一個模式。
source "$HOME/dotfiles/shell/history.sh"
