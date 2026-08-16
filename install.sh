#!/usr/bin/env bash
#
# install.sh —— 建立符號連結。這支可以無限次重跑。
#
# 用法：
#   ./install.sh          實際執行
#   ./install.sh -n       乾跑，只顯示會做什麼，不動任何檔案
#
# 這支「不」安裝任何東西。新機器請先跑 ./bootstrap.sh。

set -euo pipefail
# -e  任何指令失敗就中止
# -u  用到未定義的變數就報錯（打錯變數名時救你一命）
# -o pipefail  管線中任何一段失敗就算整條失敗，不只看最後一個

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

[[ "${1:-}" == "-n" ]] && DRY_RUN=1

# 連結對照表：「repo 內相對路徑 : 家目錄下的目標路徑」
LINKS=(
  "zsh/.zshrc:.zshrc"
  "zsh/.p10k.zsh:.p10k.zsh"
  "git/.gitconfig:.gitconfig"
)

info() { printf '  %s\n' "$*"; }
act()  { printf '\033[1m%s\033[0m\n' "$*"; }

link_one() {
  local src="$DOTFILES/$1"
  local dst="$HOME/$2"

  if [[ ! -e "$src" ]]; then
    info "跳過 $2 —— 來源不存在（$src）"
    return
  fi

  # 已經是指向正確位置的連結：什麼都不用做。
  # 這一段就是「冪等」的關鍵 —— 重跑不會產生額外動作。
  #
  # ⚠️ 用 readlink 而不是 readlink -f：
  #    -f（完全解析所有中間連結）是 GNU 專有的，macOS 的 BSD readlink 沒有，
  #    會直接報錯。不加 -f 只回傳「這個連結直接指向哪」，兩個平台都支援。
  #    我們建立連結時 $src 本來就是絕對路徑，所以直接比對就夠了。
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    info "已是最新 $2"
    return
  fi

  # 目標存在但不是我們的連結：先備份，絕不直接覆蓋。
  if [[ -e "$dst" || -L "$dst" ]]; then
    if (( DRY_RUN )); then
      info "會備份 $2 → $BACKUP_DIR/"
    else
      mkdir -p "$BACKUP_DIR"
      mv "$dst" "$BACKUP_DIR/$(basename "$2")"
      info "已備份 $2 → $BACKUP_DIR/"
    fi
  fi

  if (( DRY_RUN )); then
    info "會建立連結 ~/$2 → $src"
  else
    ln -s "$src" "$dst"
    info "已連結 ~/$2 → $src"
  fi
}

act "dotfiles 安裝"
info "來源：$DOTFILES"
(( DRY_RUN )) && act "[乾跑模式：不會修改任何檔案]"
echo

for entry in "${LINKS[@]}"; do
  link_one "${entry%%:*}" "${entry##*:}"
done

echo
if (( DRY_RUN )); then
  act "乾跑結束。拿掉 -n 才會實際執行。"
else
  act "完成。"
  info "開新終端機或執行 exec zsh 生效。"
  [[ -d "$BACKUP_DIR" ]] && info "原檔備份在 $BACKUP_DIR"
fi
