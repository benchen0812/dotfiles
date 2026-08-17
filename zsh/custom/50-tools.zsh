# 外部工具的 shell 整合
#
# 實際內容在 ~/dotfiles/shell/tools.sh —— 那是「可攜版」，
# 自足、零相依，公司機器也吃得到同一份。
#
# 這台機器上 fzf 的鍵位是由 .zshrc 的 plugins+=(fzf) 綁的（omz 的 plugin），
# 所以 tools.sh 會偵測到 fzf-history-widget 已存在而跳過綁定那一段 ——
# 行為跟以前完全一樣，也沒有多付成本。
#
# 公司機器沒有那個 plugin，tools.sh 就會自己去找 key-bindings 檔案來綁。
# 那才是它存在的理由。
#
# 這跟 40-git.zsh 是同一個模式。
source "$HOME/dotfiles/shell/tools.sh"
