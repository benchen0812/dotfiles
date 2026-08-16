# Git alias
#
# 實際內容在 ~/dotfiles/shell/git-aliases.sh —— 那個檔案是「可攜版」，
# 自足、零相依、bash 與 zsh 都能用，可以單獨複製到公司機器使用。
#
# 為什麼分開放：如果直接寫在這裡，就跟 zsh/custom/ 的載入機制綁在一起，
# 沒有整套 dotfiles 的機器就用不到。肌肉記憶只有在「每台機器都一樣」時才有價值。
#
# 這個檔案編號 40，在 .zshrc 的迴圈裡排在 oh-my-zsh 之後載入，
# 所以蓋得過 omz git plugin 的 197 個 alias（後定義的贏）。

source "$HOME/dotfiles/shell/git-aliases.sh"
