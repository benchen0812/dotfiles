#!/usr/bin/env bash
#
# work-install.sh —— 最小安裝（公司機器 / 不想動現有設定時用）
#
# 它只做一件事：在你現有的 shell 設定檔最後，加入一段 source。
# 不建符號連結、不碰 .gitconfig、不裝任何套件。
#
# 用法：
#   ./work-install.sh -c     ★ 先跑這個：檢查會跟現有 alias 撞到什麼
#   ./work-install.sh -n     乾跑，只顯示會做什麼
#   ./work-install.sh        安裝
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
  -c|--check) MODE="check" ;;
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

# ── 檢查碰撞 ─────────────────────────────────────────────────────────
#
# 裝之前先看：你現有的哪些 alias 會被蓋掉或移除。
#
# 最危險的情況是「名字相同但意義不同」—— 例如你習慣 gc = git checkout，
# 而我們定義 gc = git commit。裝完之後 gc 會靜默做別的事，不會報錯。
if [ "$MODE" = "check" ]; then
  # work-profile.sh 會載入的所有檔案。
  #
  # ⚠️ work-profile.sh 新增 source 時，這個清單也要跟著加 ——
  #    否則新檔案定義的東西會被漏報，那比沒有檢查更危險
  #    （你會以為檢查過了）。
  SOURCED=()
  for f in git-aliases.sh git-audit.sh functions.sh history.sh tools.sh; do
    [ -f "$DOTFILES/shell/$f" ] && SOURCED+=("$DOTFILES/shell/$f")
  done
  if [ "${#SOURCED[@]}" -eq 0 ]; then
    printf '找不到任何 shell/*.sh，無法檢查。\n' >&2
    exit 1
  fi

  # grep 沒命中會回非零，配上 set -e 會直接中斷腳本 —— 所以每個都要 || true。
  # -h 是「不要印檔名前綴」（grep 掃多個檔案時預設會加）。
  defines=$(grep -hoE "^alias [a-zA-Z!_]+" "${SOURCED[@]}" 2>/dev/null \
            | awk '{print $2}' | sort -u || true)
  removes=$(grep -hoE "^unalias '?[a-zA-Z!_]+'?" "${SOURCED[@]}" 2>/dev/null \
            | awk '{print $2}' | tr -d "'" | sort -u || true)

  # 函式定義：抓 `名字() {` 這種行首寫法。
  # 只抓小寫字母開頭的 —— _ 開頭的是內部輔助，不會撞到你會打的指令。
  funcs=$(grep -hoE "^[a-z][a-zA-Z0-9_-]*\(\)" "${SOURCED[@]}" 2>/dev/null \
          | tr -d '()' | sort -u || true)

  # 由外部工具在 shell 啟動時「自己產生」的名字。
  # 這些不在我們的檔案裡（是 zoxide init 吐出來的），grep 抓不到，只能寫死。
  external='z
zi'

  # ── 讀取「你現在的環境」：一次問完 ──────────────────────────────────
  #
  # 一定要 -i（互動模式）才會載入 .zshrc，才看得到你現有的 alias。
  #
  # ⚠️ 這裡只 spawn 一次，不是每個名字 spawn 一次。
  #
  #    第一版是每個名字都 `$SHELL -ic "alias $name"` —— 等於把你的 .zshrc
  #    完整跑 50 遍。在乾淨的機器上是 7 秒，但在一台有 oh-my-zsh、p10k、
  #    nvm、公司初始化腳本的機器上，每次啟動 1～2 秒就變成一兩分鐘 ——
  #    而且中途完全沒有輸出，看起來跟當機一模一樣。
  #
  #    「看起來像壞了」跟「真的壞了」對使用者是同一件事。
  #
  # < /dev/null 是另一道防護：spawn 出來的互動 shell 讀不到終端機，
  # 萬一你的 .zshrc 裡有什麼在等輸入（p10k 設定精靈、ssh-agent 密碼、
  # 公司的 y/n 確認），它會立刻拿到 EOF 而不是無限等待。
  info "正在讀取你現有的環境（載入一次 ${SHELL##*/} 設定，可能要幾秒）…"

  snapshot="$(mktemp)"
  # shellcheck disable=SC2064
  # 現在就展開 $snapshot 是刻意的 —— trap 觸發時那個變數可能已經不在了。
  trap "rm -f '$snapshot'" EXIT

  case "${SHELL:-}" in
    */bash)
      # bash 問不到「函式是哪個檔案定義的」，所以第二段只有名字。
      # 代價：在已經完整安裝的 bash 機器上會有「自己撞自己」的假警報。
      # 可以接受 —— 完整安裝走的是 zsh。
      # 第二欄要補一個 ? 佔位 —— now_func_src 讀的是第二欄，
      # 只吐名字的話它會回空字串，等於「這個函式不存在」，函式碰撞就漏報了。
      "${SHELL}" -ic 'alias
        echo "===FUNCS==="
        declare -F | cut -d" " -f3 | while read -r _k; do echo "$_k ?"; done' \
        < /dev/null > "$snapshot" 2>/dev/null || true
      ;;
    *)
      # zsh：函式那段連「定義來源檔案」一起吐出來，用來排除自己撞自己。
      "${SHELL:-/bin/zsh}" -ic '
        alias
        print -r -- "===FUNCS==="
        zmodload zsh/parameter 2>/dev/null
        for _k in ${(ko)functions}; do
          print -r -- "$_k ${functions_source[$_k]:-?}"
        done
      ' < /dev/null > "$snapshot" 2>/dev/null || true
      ;;
  esac

  if [ ! -s "$snapshot" ]; then
    printf '讀不到你現有的環境（%s -i 沒有任何輸出）。\n' "${SHELL:-zsh}" >&2
    printf '可以跳過檢查直接裝，但就看不到碰撞了：\n' >&2
    printf '  ./work-install.sh -n   然後   ./work-install.sh\n' >&2
    exit 1
  fi

  # 把快照切成兩段。之後所有查詢都是純文字比對，不再 spawn 任何東西。
  aliases_now=$(sed -n '1,/^===FUNCS===$/p' "$snapshot" | sed '$d')
  funcs_now=$(sed -n '/^===FUNCS===$/,$p' "$snapshot" | sed '1d')

  info "讀到 $(printf '%s\n' "$aliases_now" | grep -c '=' || true) 個 alias、$(printf '%s\n' "$funcs_now" | grep -c . || true) 個函式"

  # 查一個 alias 現在的值。空字串 = 這台機器沒有這個 alias。
  now_alias() {
    printf '%s\n' "$aliases_now" \
      | sed -n "s/^\(alias \)\{0,1\}$1=//p" | head -1 | sed -E "s/^'//; s/'$//"
  }

  # 查一個函式現在是哪個檔案定義的。空字串 = 沒有這個函式。
  now_func_src() {
    printf '%s\n' "$funcs_now" | awk -v n="$1" '$1 == n {print $2; exit}'
  }

  # 這個名字現在是「任何東西」嗎 —— alias、函式，或 PATH 裡的執行檔。
  # 執行檔也算撞到：我們的函式會蓋掉它。
  now_any() {
    local _a _f
    _a=$(now_alias "$1")
    if [ -n "$_a" ]; then printf 'alias %s=%s\n' "$1" "$_a"; return; fi
    _f=$(now_func_src "$1")
    if [ -n "$_f" ]; then printf '函式（定義於 %s）\n' "$_f"; return; fi
    command -v "$1" 2>/dev/null || true
  }

  echo
  act "碰撞檢查"
  echo

  conflicts=0

  printf '\033[1m會被「覆蓋成不同意義」的（最需要注意）\033[0m\n'
  found=0
  while IFS= read -r name; do
    if [ -z "$name" ]; then continue; fi
    old=$(now_alias "$name")
    if [ -z "$old" ];  then continue; fi
    new=$(grep -hE "^alias $name=" "${SOURCED[@]}" | head -1 | sed -E "s/^alias $name=//; s/^'//; s/'.*$//")
    if [ -n "$new" ] && [ "$old" != "$new" ]; then
      printf '  🔴 %-8s 現在: %-28s → 之後: %s\n' "$name" "$old" "$new"
      found=1; conflicts=$((conflicts + 1))
    fi
  done <<< "$defines"
  if [ "$found" = "0" ]; then info "（無）"; fi

  echo
  printf '\033[1m會被移除的（打了會 command not found）\033[0m\n'
  found=0
  while IFS= read -r name; do
    if [ -z "$name" ]; then continue; fi
    old=$(now_alias "$name")
    if [ -n "$old" ]; then
      printf '  🟡 %-8s 現在: %s\n' "$name" "$old"
      found=1; conflicts=$((conflicts + 1))
    fi
  done <<< "$removes"
  if [ "$found" = "0" ]; then info "（無）"; fi

  echo
  printf '\033[1m新增的函式撞到既有名字\033[0m\n'
  found=0
  while IFS= read -r name; do
    if [ -z "$name" ]; then continue; fi

    # 先問「這個函式是哪個檔案定義的」，是我們自己的就跳過。
    #
    # 為什麼需要這一步：在一台已經裝好完整 dotfiles 的機器上跑 -c，
    # 會偵測到 mkcd / biggest / git-audit 已存在而報碰撞 ——
    # 但那就是我們自己那一份。自己撞自己是假警報，
    # 而假警報的真正代價是「讓人開始忽略真警報」。
    #
    # 來源資訊出自快照裡的 $functions_source（zsh/parameter 模組）。
    src=$(now_func_src "$name")
    case "$src" in
      "$DOTFILES"/*) continue ;;
    esac

    old=$(now_any "$name")
    if [ -n "$old" ]; then
      printf '  🟠 %-8s 現在: %s\n' "$name" "$old"
      found=1; conflicts=$((conflicts + 1))
    fi
  done <<< "$funcs"
  if [ "$found" = "0" ]; then info "（無）"; fi

  echo
  printf '\033[1m外部工具會佔用的短名（zoxide）\033[0m\n'
  found=0
  while IFS= read -r name; do
    if [ -z "$name" ]; then continue; fi
    old=$(now_any "$name")

    # 已經是 zoxide 自己定義的就不算碰撞（同樣是避免自己撞自己）。
    # zoxide 產生的 alias 一律指向 __zoxide_* 開頭的函式。
    case "$old" in
      *__zoxide_*) continue ;;
    esac

    if [ -n "$old" ]; then
      printf '  🟠 %-8s 現在: %s\n' "$name" "$old"
      found=1; conflicts=$((conflicts + 1))
    fi
  done <<< "$external"
  if [ "$found" = "0" ]; then info "（無，或這台機器沒裝 zoxide）"; fi

  echo
  if [ "$conflicts" -eq 0 ]; then
    act "沒有碰撞，可以安心安裝。"
  else
    act "共 $conflicts 個碰撞。"
    info "🔴 的要特別注意 —— 那些名字之後會做不同的事，而且不會報錯。"
    info "不想改變的話，在 .zshrc 的 source 那行「之後」再定義一次即可。"
  fi

  echo
  info "以下不列入碰撞，因為它們只在「這台機器沒設過」時才生效："
  info "  FZF_DEFAULT_COMMAND / FZF_*_OPTS 等環境變數、HISTFILE"
  info "會無條件覆蓋的只有 HISTSIZE / SAVEHIST 與七個 history setopt。"
  exit 0
fi

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
