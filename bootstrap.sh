#!/usr/bin/env bash
#
# bootstrap.sh —— 新機器用，一台機器只需要跑一次。
#
# 做的事：安裝套件、clone oh-my-zsh 與 plugin。
# 需要網路，可能需要 sudo。
#
# 跑完之後接著跑 ./install.sh 建立符號連結。

set -euo pipefail

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

info() { printf '  %s\n' "$*"; }
act()  { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ── 系統套件 ─────────────────────────────────────────────────────────
# fzf   模糊搜尋。Ctrl-R 搜歷史、Ctrl-T 搜檔案、Alt-C 搜目錄後 cd
# zoxide 智慧 cd。z proj 直接跳到常去的目錄
# ripgrep 取代 grep，快很多且預設尊重 .gitignore
# fd-find 取代 find，語法人性化
# bat   取代 cat，語法高亮 + 行號
# shellcheck 寫 bash 時即時抓錯，比讀任何教材都有效
PACKAGES=(zsh git curl vim tmux fzf zoxide ripgrep fd-find bat shellcheck)

act "安裝系統套件"
if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y "${PACKAGES[@]}"
else
  info "非 apt 系統，請自行安裝：${PACKAGES[*]}"
fi

# Debian/Ubuntu 把這兩個工具改了名字，避免與既有套件衝突。
# 建立連結讓它們用大家熟悉的名字。
act "修正 Debian 系的指令改名"
mkdir -p "$HOME/.local/bin"
[[ -x /usr/bin/fdfind  ]] && ln -sf /usr/bin/fdfind  "$HOME/.local/bin/fd"  && info "fdfind → fd"
[[ -x /usr/bin/batcat  ]] && ln -sf /usr/bin/batcat  "$HOME/.local/bin/bat" && info "batcat → bat"

# ── oh-my-zsh ────────────────────────────────────────────────────────
act "oh-my-zsh"
if [[ -d "$ZSH_DIR" ]]; then
  info "已存在，跳過"
else
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
  info "已安裝"
fi

# ── 主題與 plugin ────────────────────────────────────────────────────
# 這些都是別人的 repo，所以裝在 oh-my-zsh 自己的 custom 目錄底下，
# 不進我們的 dotfiles repo。界線要清楚：
#   別人的程式碼 → ~/.oh-my-zsh/
#   我的設定     → ~/dotfiles/
clone_if_missing() {
  local url="$1" dst="$2" name="$3"
  if [[ -d "$dst" ]]; then
    info "$name 已存在，跳過"
  else
    git clone --depth=1 "$url" "$dst"
    info "$name 已安裝"
  fi
}

act "主題與 plugin"
clone_if_missing https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" "powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"

# ── git 身分設定檔 ───────────────────────────────────────────────────
# 這個檔案不版控（含 email，而且會隨環境改變），所以每台新機器都要重建。
# 只產生範本，實際內容由你填 —— 腳本不該猜你的身分。
act "git 身分設定檔"
GITLOCAL="$HOME/.gitconfig.local"
if [[ -f "$GITLOCAL" ]]; then
  info "$GITLOCAL 已存在，跳過"
else
  cat > "$GITLOCAL" <<'EOF'
# ~/.gitconfig.local —— 身分設定，不版控
#
# 由 ~/dotfiles/git/.gitconfig 最下方的 [include] 載入。
#
# 為什麼身分不進 dotfiles repo：
#   那個 repo 是跨機器的工具庫，只放「行為」（alias、diff 演算法…），
#   不放會隨環境改變的東西。這台機器用個人 email、公司機器用公司 email，
#   所以身分屬於機器，不屬於 repo。
#
# ⚠️ 填完再開始 commit。因為 .gitconfig 設了 useConfigOnly = true，
#    這裡沒填的話 git 會直接報錯，而不是默默用 <使用者名>@<主機名> 湊一個
#    然後把它永久寫進歷史。

[user]
	name = Ben
	email = 填你的email@example.com
EOF
  info "已產生範本：$GITLOCAL"
  info "→ 請立刻編輯它填入 email，否則 commit 會報錯"
fi

# ── 預設 shell ───────────────────────────────────────────────────────
act "預設 shell"
if [[ "$SHELL" == */zsh ]]; then
  info "已經是 zsh"
else
  info "執行 chsh -s \"\$(command -v zsh)\" 切換（需要輸入密碼）"
fi

act "bootstrap 完成"
info "接著執行：./install.sh"
