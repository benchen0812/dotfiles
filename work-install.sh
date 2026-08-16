#!/usr/bin/env bash
#
# work-install.sh —— 最小安裝（公司機器 / 不想動現有設定時用）
#
# 它只做一件事：在你現有的 shell 設定檔最後，加入一段 source。
# 不建符號連結、不碰 .gitconfig、不裝任何套件。
#
# 用法：
#   ./work-install.sh        安裝
#   ./work-install.sh -n     乾跑，只顯示會做什麼
#   ./work-install.sh -u     移除
#
# 完整安裝（你自己的機器）請用 ./bootstrap.sh + ./install.sh。

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$DOTFILES/shell/work-profile.sh"

# 標記區塊。移除時靠這兩行定位，才不會誤刪你自己寫的東西。
# 這是 conda / nvm 那類工具用的慣例。
BEGIN_MARK="# >>> dotfiles work-profile >>>"
END_MARK="# <<< dotfiles work-profile <<<"

MODE="install"
case "${1:-}" in
  -n) MODE="dryrun"    ;;
  -u) MODE="uninstall" ;;
  -h|--help) sed -n '2,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
  "") ;;
  *)  printf '未知參數：%s（用 -h 看說明）\n' "$1" >&2; exit 1 ;;
esac

info() { printf '  %s\n' "$*"; }
act()  { printf '\033[1m%s\033[0m\n' "$*"; }

# ── 找出要改哪個設定檔 ───────────────────────────────────────────────
#
# 依「你現在用的 shell」決定，而不是猜。
# $SHELL 是登入 shell（chsh 設定的那個），比 $0 可靠。
detect_rc() {
  case "${SHELL:-}" in
    */zsh)  printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc" ;;
    */bash) printf '%s\n' "$HOME/.bashrc" ;;
    *)
      # 認不出來就看哪個檔案存在
      if   [ -f "$HOME/.zshrc" ];  then printf '%s\n' "$HOME/.zshrc"
      elif [ -f "$HOME/.bashrc" ]; then printf '%s\n' "$HOME/.bashrc"
      else return 1
      fi
      ;;
  esac
}

RC="$(detect_rc)" || {
  printf '找不到 .zshrc 或 .bashrc，無法自動安裝。\n' >&2
  printf '請手動在你的 shell 設定檔加入：\n' >&2
  printf '  source %s\n' "$PROFILE" >&2
  exit 1
}

act "dotfiles 最小安裝"
info "設定檔：${RC/#$HOME/\~}"
info "來源　：${PROFILE/#$HOME/\~}"
echo

# ── 前置檢查 ─────────────────────────────────────────────────────────
if [ ! -f "$PROFILE" ]; then
  printf '找不到 %s\n' "$PROFILE" >&2
  exit 1
fi

# grep -F 是「純文字比對」，不把內容當正則表達式處理。
# 標記裡有 > 和 < ，用一般 grep 沒問題，但 -F 更保險也更快。
already_installed() { [ -f "$RC" ] && grep -qF "$BEGIN_MARK" "$RC"; }

# ── 移除 ─────────────────────────────────────────────────────────────
if [ "$MODE" = "uninstall" ]; then
  if ! already_installed; then
    info "沒有安裝過，不需要移除"
    exit 0
  fi
  backup="$RC.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$RC" "$backup"

  # 刪除兩個標記之間（含標記本身）的所有行。
  #
  # ⚠️ 不用 sed -i —— GNU（Linux）與 BSD（macOS）的 -i 語法不同：
  #      Linux:  sed -i 's/a/b/' file
  #      macOS:  sed -i '' 's/a/b/' file      ← 多一個空字串參數
  #    寫錯的話 macOS 會噴 "invalid command code"。
  #    改用 awk 產生新內容再寫回，兩個平台行為完全一致。
  #
  # 最後用 cat > 而不是 mv：保留原檔的權限與 inode
  # （mv 會把暫存檔的權限一起帶過去）。
  #
  # 安裝時在區塊前面加了一個空行（跟你原本的內容隔開），移除時要一起清掉，
  # 否則反覆安裝／移除會累積空行 —— 三個循環就多三行。
  #
  # 作法：把連續空行先存進陣列不要立刻輸出。
  #   - 遇到起始標記 → 只丟掉「最後一個」空行（那個是我們加的），
  #                    前面的照樣輸出（那些是你原本就有的）
  #   - 遇到一般內容 → 先把緩衝倒出來再輸出
  #   - 檔案結尾     → 倒出緩衝（保留你原本的結尾空行）
  #
  # 只丟一個是關鍵：如果整批丟棄，你原本的結尾空行會被一起吃掉。
  tmp="$(mktemp)"
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0 == b            { for (i = 1; i < nb; i++) print blanks[i]   # 少印最後一個
                         nb = 0; skip = 1; next }
    $0 == e            { skip = 0; next }
    skip               { next }
    /^[[:space:]]*$/   { blanks[++nb] = $0; next }
                       { for (i = 1; i <= nb; i++) print blanks[i]
                         nb = 0; print }
    END                { for (i = 1; i <= nb; i++) print blanks[i] }
  ' "$RC" > "$tmp"
  cat "$tmp" > "$RC"
  rm -f "$tmp"

  info "已移除標記區塊"
  info "原檔備份：${backup/#$HOME/\~}"
  echo
  act "完成。執行 exec zsh 生效。"
  exit 0
fi

# ── 已安裝就不重複加 ─────────────────────────────────────────────────
# 這是冪等性的關鍵：重跑一百次結果都一樣，不會堆出一百行 source。
if already_installed; then
  act "已經安裝過了，不做任何事。"
  info "要移除請執行：./work-install.sh -u"
  exit 0
fi

# ── 安裝 ─────────────────────────────────────────────────────────────
BLOCK="
${BEGIN_MARK}
[ -f \"${PROFILE}\" ] && source \"${PROFILE}\"
${END_MARK}"

if [ "$MODE" = "dryrun" ]; then
  act "[乾跑模式：不會修改任何檔案]"
  info "會在 ${RC/#$HOME/\~} 最後加入："
  printf '%s\n' "$BLOCK" | sed 's/^/      /'
  echo
  act "拿掉 -n 才會實際執行。"
  exit 0
fi

# 先備份再改，絕不直接覆蓋 —— 跟 install.sh 同一個原則
backup="$RC.bak.$(date +%Y%m%d-%H%M%S)"
[ -f "$RC" ] && cp "$RC" "$backup" && info "已備份：${backup/#$HOME/\~}"

# 一定要用 >> （附加）而不是 > （覆蓋）。
# 這正是這支腳本存在的主要理由 —— 手打時少一個字元就會清空你的設定檔。
printf '%s\n' "$BLOCK" >> "$RC"
info "已加入標記區塊到 ${RC/#$HOME/\~} 最後"

echo
act "完成。"
info "執行 exec zsh 或開新終端機生效。"
info "移除：./work-install.sh -u"
