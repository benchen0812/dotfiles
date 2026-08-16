# 環境變數與 PATH
#
# PATH 集中在這一個地方管理。原本散在 .zshrc 的兩處（前後隔著 p10k 的 source），
# 功能上沒錯但很難看出最終順序 —— 這是搬進版控後第一個被修掉的問題。

# PATH：越前面優先權越高
export PATH="$HOME/.local/bin:$PATH"        # pipx、pip --user 等裝的東西
export PATH="$HOME/.npm-global/bin:$PATH"   # npm 全域套件（避免 sudo npm -g）

# 預設編輯器：git commit、crontab -e、less 的 v 鍵都會用到
export EDITOR=vim
export VISUAL=vim

# 語系。註解掉 —— 需要時再開，避免在沒產生 locale 的機器上噴警告。
# export LANG=en_US.UTF-8
