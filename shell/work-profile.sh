# ═══════════════════════════════════════════════════════════════════════
# work-profile.sh —— 公司機器 / 不想動現有設定時的入口
# ═══════════════════════════════════════════════════════════════════════
#
# 用途：把 git alias 與稽核工具加進一台「已經有自己的 .zshrc」的機器，
#       而完全不動它現有的任何設定。
#
# ── 安裝 ────────────────────────────────────────────────────────────
#
#   git clone <repo> ~/dotfiles
#
#   然後在現有 ~/.zshrc 的【最後一行】加：
#
#     [ -f ~/dotfiles/shell/work-profile.sh ] && source ~/dotfiles/shell/work-profile.sh
#
#   ⚠️ 一定要加在最後面 —— 才蓋得過前面 oh-my-zsh 的定義（後定義的贏）。
#   前面的 [ -f ... ] && 是保險：檔案不在時靜默跳過，不會噴錯。
#
# ── 移除 ────────────────────────────────────────────────────────────
#
#   刪掉那一行，exec zsh。環境立刻回到原狀。
#   一行加、一行刪，完全可逆 —— 這是它跟 install.sh 的根本差別。
#
# ── 這裡「不做」什麼 ────────────────────────────────────────────────
#
#   不碰 ~/.zshrc（不建符號連結）
#   不碰 ~/.gitconfig     ← 公司的 git 身分在裡面，換掉會出事
#   不碰 ~/.p10k.zsh      ← 公司的外觀設定可能不同
#   不裝任何套件
#
#   完整安裝請用 ../install.sh 與 ../bootstrap.sh，那是給你自己的機器的。


# ── 找出這個檔案所在的目錄 ──────────────────────────────────────────
#
# 不能用 $(dirname "$0")：在「被 source 的檔案」裡，$0 的意義 bash 與 zsh 不同。
#   zsh  → 檔案路徑（可用）
#   bash → shell 名稱如 -bash（dirname 會算出錯誤的目錄）
#
# 所以分開處理：
#   zsh  的 %x  展開為「目前正在讀的檔案」，:A 取絕對路徑，:h 取目錄
#   bash 的 BASH_SOURCE[0] 是被 source 的檔案路徑
_wp_dir=""
if [ -n "$ZSH_VERSION" ]; then
  _wp_dir="${${(%):-%x}:A:h}"
elif [ -n "$BASH_VERSION" ]; then
  _wp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi

# 萬一兩種都判斷不出來（其他 shell），退回寫死的預設路徑
[ -z "$_wp_dir" ] && _wp_dir="$HOME/dotfiles/shell"


# ── 載入 ────────────────────────────────────────────────────────────
#
# 46 個 git alias，並移除 13 個危險或易混淆的（含 gp / gl）。
# 移除 gp/gl 是刻意的：這正是「換掉舊習慣」的機制。
[ -f "$_wp_dir/git-aliases.sh" ] && source "$_wp_dir/git-aliases.sh"

# git-audit 函式：機器消失前，找出只存在本機的工作
[ -f "$_wp_dir/git-audit.sh" ] && source "$_wp_dir/git-audit.sh"

unset _wp_dir
